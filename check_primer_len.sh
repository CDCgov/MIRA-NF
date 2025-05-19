#!/bin/bash

# Usage: ./line_lengths.sh /path/to/folder

if [[ $# -ne 1 ]]; then

    echo "Usage: $0 <folder>"

    exit 1

fi

folder="$1"

# Make sure it's a directory

if [[ ! -d "$folder" ]]; then

    echo "Error: $folder is not a directory"

    exit 1

fi

for file in "$folder"/*; do

    if [[ -f "$file" ]]; then

        awk -v filename="$(basename "$file")" '

            /^[^>]/ {

                len = length($0)

                if (min == "" || len < min) min = len

                if (len > max) max = len

            }

            END {

                if (min != "" && max != "")

                    printf "%s:\n  Shortest line length: %d\n  Longest line length: %d\n\n", filename, min, max

                else

                    printf "%s:\n  No lines found that do not start with >\n\n", filename

            }

        ' "$file"

    fi

done
