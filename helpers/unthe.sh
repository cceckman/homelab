#!/bin/sh

find . -maxdepth 1 -name 'The *' | \
while read THE
do
	TARGET="$(echo "$THE" | sed 's!./The \(.*\)$!./\1, The!')"
	echo >&2 "$THE" to "$TARGET"

	rsync --itemize-changes --update \
		--recursive \
		--progress --partial \
		"$THE"/ "$TARGET"
	rm -rf "$THE"
done
