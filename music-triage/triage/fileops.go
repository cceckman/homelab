package triage

import (
	"fmt"
	"io"
	"os"
	"path"
	"path/filepath"
)

// move from src to dest. Uses a simple rename if possible; otherwise, copies.
func move(dest, src string) error {
	// First the easy version: if they're on the same FS...
	if err := os.Rename(src, dest); err == nil {
		return nil
	}
	// Not so easy. Make a copy.
	// First, prep the target directory:
	if err := os.MkdirAll(filepath.Dir(dest), 0755); err != nil {
		return fmt.Errorf("could not create target directory: %w", err)
	}

	// In an inner scope, perform the copy:
	err := func() error {
		to, err := os.Create(dest)
		if err != nil {
			return fmt.Errorf("could not create target file: %w", err)
		}
		defer to.Close()
		from, err := os.Open(src)
		if err != nil {
			return fmt.Errorf("could not open source file: %w", err)
		}
		defer from.Close()
		_, err = io.Copy(to, from)
		return err
	}()
	if err != nil {
		return err
	}

	// Copy complete; delete the original.
	return os.Remove(src)
}

// Cleans all empty directories within the specified directory.
// "hasContent" reflects if the directory is empty after cleaning, i.e. if there
// is a file somewhere within the tree.
func pruneTree(dir string) (hasContent bool, err error) {
	defer func() {
		if err != nil {
			err = fmt.Errorf("while processing directory %q: %w", dir, err)
		}
	}()

	// Depth-first recursion,
	hasContent = false
	entries, err := os.ReadDir(dir)
	if os.IsNotExist(err) {
		return false, nil
	}
	if err != nil {
		return true, err
	}
	for _, entry := range entries {
		if !entry.IsDir() {
			hasContent = true
			// Move on to the next entry
			continue
		}
		// It's a directory.
		// Clean recursively; then remove if empty.
		subDir := path.Join(dir, entry.Name())
		subdirContent, err := pruneTree(subDir)
		if err != nil {
			return true, err
		}
		hasContent = hasContent || subdirContent
		if !subdirContent {
			if err := os.Remove(subDir); err != nil {
				return true, err
			}
		}
	}
	return
}
