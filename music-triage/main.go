package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"path"
	"text/template"

	"github.com/cceckman/homelab/music-triage/triage"
)

const (
	usage string = `
musictriage sorts music files into folders based on their embedded tags.

When invoked, musictriage reads the files in the -intake directory and inspects their metadata tags (ID3 or similar) and format. On success, musictriage moves the file into a subdirectory of -library - specifically, into the relative path specified by -targetTemplate.

If musictriage cannot read the file, if the file is DRM-protected and -handleDrm is false, or if any other error occurs, musictriage emits a log message and moves the file to the -quarantine directory.

The short version of -targetTemplate:

	{{ .Property }}

gets substituted with the value of "Property". Properties available include:

- Album, AlbumArtist, Format, FileType, Title, Album, Artist, AlbumArtist, Composer, Year, Genre - derived directly from tags
- Track: The track number on this disc
- Tracks: The number of tracks on this disc
- Discs: The number of discs in this album
- Disc: The disk this track is from
- ZeroTrack, ZeroDisc: As Track / Disc, but two digits (leading zero)
- Extension: The extension of the original file

Note that these might have their "zero values" (e.g. 0, empty string) if the underlying file does not report them.

(The version for developers: this is a template for the text/template Golang package, with the triage.Track object as the backing item. This type embeds github.com/dhowden/tag.Metadata.)

`
)

var (
	help = flag.Bool("help", false, "print a help message and exit")

	intake = flag.String("intake", "", "directory to read files from")

	library        = flag.String("library", "", "music library directory, to put triaged files into")
	targetTemplate = flag.String("targetTemplate", triage.DefaultTemplate, "template (from text/template package) for file paths within library. See --help message for valid substitutions")

	quarantine = flag.String("quarantine", "", "directory to put invalid files into")

	// TODO: Support -handleDrm. It looks like `tag` isn't picking up M4P?
	// handleDrm  = flag.Bool("handleDrm", true, "whether DRM-protected files should be placed in -library; if false, DRMed files are placed into -quarantine instead")
)

func main() {
	flag.Parse()
	flag.Usage = func() {
		fmt.Fprintf(flag.CommandLine.Output(), "Usage of %s:\n", os.Args[0])
		fmt.Fprint(flag.CommandLine.Output(), usage)
		flag.PrintDefaults()
	}
	if *help {
		flag.Usage()
		os.Exit(1)
	}

	t, err := template.New("path").Parse(*targetTemplate)
	if err != nil {
		fmt.Fprintf(flag.CommandLine.Output(), "could not parse -targetTemplate: %s", err)
		os.Exit(1)
	}

	s := triage.Settings{
		LibraryRoot:    path.Clean(*library),
		QuarantineRoot: path.Clean(*quarantine),
		IntakeRoot:     path.Clean(*intake),
		Template:       t,
	}
	if err := s.Run(); err != nil {
		log.Fatal(err)
	}
	log.Print("Done!")
}
