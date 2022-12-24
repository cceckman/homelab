package triage_test

import (
	"io"
	"io/ioutil"
	"os"
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
func makeTestSettings(t *testing.T) triage.Settings {
	t.Helper()
	dir, err := ioutil.TempDir(os.TempDir(), "")
	if err != nil {
		panic(err)
	}
	t.Cleanup(func() {
		os.RemoveAll(dir)
	})
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

// Puts the file embedded as "name" into the intake directory of s.
func putFileInIntake(t *testing.T, s *triage.Settings, name string) {
	t.Helper()
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
	path := filepath.Join(s.IntakeRoot, name)
	if err := os.MkdirAll(filepath.Dir(path), 0755); err != nil {
		t.Fatal(err)
	}

	out, err := os.Create(path)
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

// Validates that the directory is empty.
func checkEmpty(t *testing.T, dir string) {
	t.Helper()
	ent, err := os.ReadDir(dir)
	if err != nil && !os.IsNotExist(err) {
		t.Fatal(err)
	}
	if len(ent) != 0 {
		t.Errorf("directory %q has unexpected contents", dir)
		for _, e := range ent {
			t.Logf("contents: %q", e.Name())
		}
		t.FailNow()
	}
}

// Entry for table-driven test of correct triage.
type correctTriageTest struct {
	name            string
	filename        string
	template        string
	wantLibraryPath string
}

var correctTriageTests = []correctTriageTest{
	{
		name:            "SortByArtist",
		filename:        "testdata/artist.m4a",
		template:        triage.DefaultTemplate,
		wantLibraryPath: "Charles Eckman/Testdata/01.m4a",
	},
	{
		name:            "SortByAlbumArtist",
		filename:        "testdata/album-artist.m4a",
		template:        triage.DefaultTemplate,
		wantLibraryPath: "Charles Eckman/Testdata/01.m4a",
	},
	{
		name:            "IncludeDisc",
		filename:        "testdata/multi-disc.m4a",
		template:        triage.DefaultTemplate,
		wantLibraryPath: "Charles Eckman/Testdata/02-01.m4a",
	},
}

func TestTestCorrectTriage(t *testing.T) {
	for _, test := range correctTriageTests {
		name := test.name
		t.Run(name, func(t *testing.T) {
			s := makeTestSettings(t)
			s.Template = template.Must(template.New("").Parse(test.template))
			putFileInIntake(t, &s, test.filename)

			if err := s.Run(); err != nil {
				t.Fatal(err)
			}

			wantPath := filepath.Join(s.LibraryRoot, test.wantLibraryPath)
			_, err := os.Stat(wantPath)
			if err != nil {
				t.Fatalf("didn't find file at expected path: %s", err)
			}

			checkEmpty(t, s.IntakeRoot)
			checkEmpty(t, s.QuarantineRoot)
		})
	}
}

type quarantineTest struct {
	name     string
	filename string
	template string
}

var quarantineTests = []correctTriageTest{
	{
		name:     "NoTags",
		filename: "testdata/notags.m4a",
		template: triage.DefaultTemplate,
	},
	{
		name:     "NotMusic",
		filename: "testdata/cover.jpg",
		template: triage.DefaultTemplate,
	},
}

func TestRejectNoAlbum(t *testing.T) {
	for _, test := range quarantineTests {
		name := test.name
		t.Run(name, func(t *testing.T) {
			s := makeTestSettings(t)
			s.Template = template.Must(template.New("").Parse(test.template))
			putFileInIntake(t, &s, test.filename)

			if err := s.Run(); err != nil {
				t.Fatal(err)
			}

			wantPath := filepath.Join(s.QuarantineRoot, test.filename)
			_, err := os.Stat(wantPath)
			if err != nil {
				t.Fatalf("didn't find file at expected path: %s", err)
			}

			checkEmpty(t, s.IntakeRoot)
			checkEmpty(t, s.LibraryRoot)
		})
	}
}
