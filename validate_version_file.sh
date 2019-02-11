#!/bin/sh

find \!CONFIG -type f | awk '
NR==FNR {
	# stdin
	seen[$0]++
	next
}
/!CONFIG/ {
	# version.xml
	line = gensub(/^.*<file version=\"[0-9]+(\.?[0-9]+)?\">(\!CONFIG.*)<\/file>.*$/, "\\2", 1)
	seen[line] = seen[line] + 2
}
END {
	for (line in seen) {
		if (seen[line] == 1)
			printf "Untracked file:\n %s\n\n", line
		else if (seen[line] == 2)
			printf "Missing file:\n %s\n\n", line
		else if (seen[line] > 3) {
			if (seen[line] % 2) {
				printf "Duplicate line (%dx) in version file:\n %s\n\n",
					seen[line] / 2, line
			} else {
				printf "Missing file and duplicate line (%dx) in version file:\n %s\n\n",
					seen[line] / 2, line
			}
		}
	}
}' - "version.xml"
