package triage

import (
	"bytes"
	"fmt"
	"io/fs"
	"log"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"text/template"

	"github.com/dhowden/tag"
	"github.com/hashicorp/go-multierror"
)

// The default template for file locations.
const DefaultTemplate = "{{ .AlbumOrTrackArtist }}/{{ .Album }}/{{ if gt .Discs 1 }}{{ .ZeroDisc }}-{{ end }}{{ .ZeroTrack }}.{{ .Extension }}"

// TODO: Unzip archives before triaging
// TODO: Support "artist override" special tag, to be used in preference to AlbumArtist / TrackArtist

// Settings for the music triager;
// these correspond to the flags in the main binary.
type Settings struct {
	LibraryRoot    string
	QuarantineRoot string
	IntakeRoot     string
	Template       *template.Template
}

func (s *Settings) Run() error {
	var wg sync.WaitGroup

	// We us a heuristic of N*GOMAXPROC for the number of worker threads to run;
	// we expect many to be blocked in the OS.
	count := 2 * runtime.GOMAXPROCS(0)
	// We run count worker threads, plus a generator thread.
	wg.Add(count + 1)

	// The generator thread is responsible for closing "input" when done,
	// and shutting down the input channel (it's the only writer).
	input := make(chan TriageFile, count)
	errors := make(chan error, count)
	go func() {
		defer close(input)
		defer wg.Done()
		err := fs.WalkDir(os.DirFS(s.IntakeRoot), ".", func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if d.IsDir() {
				return nil
			}
			input <- TriageFile{
				IntakePath:     filepath.Join(s.IntakeRoot, path),
				QuarantinePath: filepath.Join(s.QuarantineRoot, path),
				Settings:       s,
			}
			return nil
		})
		if err != nil {
			errors <- err
		}
	}()

	// The worker threads read from input, and may generate errors.
	for i := 0; i < count; i += 1 {
		go func() {
			defer wg.Done()
			for f := range input {
				if err := f.tryEmplace(); err != nil {
					errors <- err
				}
			}
		}()
	}
	// A final thread: when all error-generators are done, we're done.
	go func() {
		wg.Wait()
		close(errors)
	}()

	// Collect errors from the above.
	var errs error
	for err := range errors {
		multierror.Append(errs, err)
	}
	if errs != nil {
		return errs
	}

	return errs
}

// A single file to sort and place
type TriageFile struct {
	IntakePath     string
	QuarantinePath string
	*Settings
}

// Try to move the file to a new location; on error, try to move to quarantine.
func (s *TriageFile) tryEmplace() (err error) {
	err = s.moveToLibrary()
	if err == nil {
		return nil
	}

	log.Printf("could not handle file %q; placing into quarantine: %s", s.IntakePath, err)

	return move(s.IntakePath, s.QuarantinePath)
}

// Move the file to the library.
func (s *TriageFile) moveToLibrary() (err error) {
	defer func() {
		if err != nil {
			err = fmt.Errorf("in processing %q: %w", s.IntakePath, err)
		}
	}()

	rd, err := os.Open(s.IntakePath)
	if err != nil {
		return fmt.Errorf("could not open for intake: %w", err)
	}
	closed := false
	defer func() {
		if !closed {
			rd.Close()
		}
	}()
	m, err := tag.ReadFrom(rd)
	if err != nil {
		return fmt.Errorf("could not get tag metadata: %w", err)
	}

	track := Track{
		Metadata:     m,
		originalFile: s.IntakePath,
	}
	b := &bytes.Buffer{}
	if err := s.Template.Execute(b, &track); err != nil {
		return fmt.Errorf("could not evaluate path template: %w", err)
	}
	targetPath := string(b.Bytes())

	// Check that there are no empty path segments:
	for _, segment := range filepath.SplitList(targetPath) {
		if segment == "" {
			return fmt.Errorf("target path %q had an empty segment", targetPath)
		}
	}

	// Alright, we're good to go.
	closed = true
	if err := rd.Close(); err != nil {
		return fmt.Errorf("could not close original file: %w", err)
	}

	return move(filepath.Join(s.LibraryRoot, targetPath), s.IntakePath)
}

// Track is a single file that can be placed into the library.
type Track struct {
	tag.Metadata
	originalFile string
}

// Returns the album or track artist -
// album artist if specified, track artist otherwise.
func (t *Track) AlbumOrTrackArtist() string {
	if a := t.AlbumArtist(); a != "" {
		return a
	}
	return t.Artist()
}

func (t *Track) Discs() int {
	_, n := t.Metadata.Disc()
	return n
}

func (t *Track) Disc() int {
	n, _ := t.Metadata.Disc()
	return n
}

func (t *Track) ZeroDisc() string {
	n, _ := t.Metadata.Disc()
	return fmt.Sprintf("%02d", n)
}

func (t *Track) Extension() string {
	return strings.TrimPrefix(filepath.Ext(t.originalFile), ".")
}

func (t *Track) Track() int {
	track, _ := t.Metadata.Track()
	return track
}

func (t *Track) ZeroTrack() string {
	track, _ := t.Metadata.Track()
	return fmt.Sprintf("%02d", track)
}

func (t *Track) Tracks() int {
	_, tracks := t.Metadata.Track()
	return tracks
}
