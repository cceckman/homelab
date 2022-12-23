package triage_test

import (
	"io"
	"io/ioutil"
	"os"
	"path"
	"path/filepath"
	"testing"
	"text/template"

	"embed"

	"github.com/cceckman/homelab/music-triage/triage"
)

//go:embed testdata/*
var testdata embed.FS

// Make a directory for testing
// - An intake directory, which exists
// - A quarantine directory, which doesn't yet exist
// - A library diretory, which exists
// - The default template (subject to editing)
func makeTestSettings() triage.Settings {
	dir, err := ioutil.TempDir(os.TempDir(), "")
	if err != nil {
		panic(err)
	}
	intake := filepath.Join(dir, "intake")
	library := filepath.Join(dir, "library")
	quarantine := filepath.Join(dir, "quarantine")
	if err := os.MkdirAll(intake, 0755); err != nil {
		panic(err)
	}

	return triage.Settings{
		LibraryRoot:    library,
		IntakeRoot:     intake,
		QuarantineRoot: quarantine,
		Template:       template.Must(template.New("path").Parse(triage.DefaultTemplate)),
	}
}

func putFileInIntake(t *testing.T, s *triage.Settings, name string) {
	in, err := testdata.Open(name)
	if err != nil {
		t.Fatal(err)
	}
	defer in.Close()
	stat, err := in.Stat()
	if err != nil {
		t.Fatal(err)
	}
	wantCount := stat.Size()
	out, err := os.Create(filepath.Join(s.IntakeRoot, filepath.Base(name)))
	if err != nil {
		t.Fatal(err)
	}
	defer out.Close()
	gotCount, err := io.Copy(out, in)
	if err != nil {
		t.Fatal(err)
	}
	if gotCount != wantCount {
		t.Fatalf("did not copy full file contents: got: %d want: %d", gotCount, wantCount)
	}
}

func TestTriageWithArtist(t *testing.T) {
	s := makeTestSettings()
	putFileInIntake(t, &s, "testdata/artist.m4a")

	if err := s.Run(); err != nil {
		t.Fatal(err)
	}

	wantPath := path.Join(s.LibraryRoot, "Charles Eckman/Testdata/01.m4a")
	_, err := os.Stat(wantPath)
	if err != nil {
		t.Fatalf("didn't find file at expected path: %s", err)
	}
}

func TestTriageWithAlbumArtist(t *testing.T) {
	s := makeTestSettings()
	putFileInIntake(t, &s, "testdata/album-artist.m4a")

	if err := s.Run(); err != nil {
		t.Fatal(err)
	}

	wantPath := path.Join(s.LibraryRoot, "Charles Eckman/Testdata/01.m4a")
	_, err := os.Stat(wantPath)
	if err != nil {
		t.Fatalf("didn't find file at expected path: %s", err)
	}
}

func TestTriageWithDisc(t *testing.T) {
	s := makeTestSettings()
	putFileInIntake(t, &s, "testdata/multi-disc.m4a")

	if err := s.Run(); err != nil {
		t.Fatal(err)
	}

	wantPath := path.Join(s.LibraryRoot, "Charles Eckman/Testdata/02-01.m4a")
	_, err := os.Stat(wantPath)
	if err != nil {
		t.Fatalf("didn't find file at expected path: %s", err)
	}
}
