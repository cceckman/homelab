package triage

import (
	"fmt"
	"path/filepath"
	"strings"

	"github.com/dhowden/tag"
)

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
