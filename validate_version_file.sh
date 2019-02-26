#!/bin/sh
#
# Called by "git commit" with no arguments.  The hook should
# exit with non-zero status after issuing an appropriate message if
# it wants to stop the commit.
#
# To enable this hook, rename this file to "pre-commit" and move it
# to .git/hooks/

file="version.xml"

set -e
exec 1>&2

errexit()
{
	echo "Commit aborted due to errors in '$file'"
	exit 1
}

# check for xml errors
if command -v "xmllint" >/dev/null 2>&1; then
	xmllint --noout "$file" || errexit
else
	echo "xmllint missing, try installing libxml2"
fi

find \!CONFIG -type f | awk '
NR==FNR {
	# stdin
	seen[$0]++
	next
}
/^[[:space:]]*<file[[:space:]].*<\/file>/ {
	# $file
	line = gensub(/^[[:space:]]*<file version=\"[0-9]+(\.?[0-9]+)?\">(.*)<\/file>[[:space:]]*$/, "\\2", 1)
	seen[line] = seen[line] + 2

	if (line !~ /^\!CONFIG/ \
		&& seen[line] % 2 == 0 \
		&& system("[ -f " line " ]") == 0)
			seen[line]++
}
END {
	err = 0
	for (line in seen) {
		if (seen[line] == 1) {
			printf "Untracked file:\n %s\n\n", line
		} else if (seen[line] == 2) {
			err = 1
			printf "Missing file:\n %s\n\n", line
		} else if (seen[line] > 3) {
			err = 1
			if (seen[line] % 2) {
				printf "Duplicate line (%dx):\n %s\n\n",
					seen[line] / 2, line
			} else {
				printf "Missing file and duplicate line (%dx):\n %s\n\n",
					seen[line] / 2, line
			}
		}
	}
	exit err
}' - "$file" || errexit
