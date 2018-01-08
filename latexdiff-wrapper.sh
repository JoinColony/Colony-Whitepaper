#!/bin/sh
# This script was made because latexdiff-vc was acting up
# and not handling bibliographies satisfactorily.
# Taken from https://github.com/ftilmann/latexdiff/pull/127

help () {
    echo "Usage: $0 [-d|--dir <dir>]" \
        "<file>[.tex] [<old_commit> [<new_commit>]]"
}

# default options
dest="diff"
file=""
a="HEAD"
b=""

# parse options
while [ $# -gt 0 ]; do
    case "$1" in
        -d|--dir)       dest="$2"; shift 2 ;;
        -h|-\?|--help)  help; exit 0 ;;
        --)             shift; break ;;
        -*)             echo "Unknown option $1" >&2; help>&2; exit 1 ;;
        *)              break;;
    esac
done

if [ $# -lt 1 -o $# -gt 3 ]; then
    echo "Wrong number of arguments" >&2; help>&2; exit 1
fi

[ $# -ge 1 ] && file="$1"
[ $# -ge 2 ] && a="$2"
[ $# -ge 3 ] && b="$3"

# fetch paths
temp="$(mktemp -d)"
proj="$(git rev-parse --show-toplevel)"
path="$(git rev-parse --show-prefix)"

# sanitize values
temp="$(realpath "$temp")"
proj="$(realpath "$proj")"
dest="$(realpath "$dest")"
file="${file%.tex}"

# clone repositories
cd "$proj"

mkdir -p "$temp/a"
if [ -n "$a" ]; then
    git archive --format=tar "$a" | tar xf - -C "$temp/a"
else
    git ls-files -z | xargs -0 tar cf - | tar xf - -C "$temp/a"
fi

mkdir -p "$temp/b"
if [ -n "$b" ]; then
    git archive --format=tar "$b" | tar xf - -C "$temp/b"
else
    git ls-files -z | xargs -0 tar cf - | tar xf - -C "$temp/b"
fi

# generate .bbl (optional?)
if true; then
    cd "$temp/a/$path"
    pdflatex "$file" -draftmode
    bibtex "$file"

    cd "$temp/b/$path"
    pdflatex "$file" -draftmode
    bibtex "$file"
fi

# run latexdiff
mkdir -p "$dest"
latexdiff --flatten "$temp/a/$path/$file.tex" "$temp/b/$path/$file.tex" \
    > "$dest/$file.tex"

# combine all old files and new files (added/removed figures, etc)
cp -anT "$temp/a" "$temp/b"

# compile LaTeX, with access to other files
cd "$temp/b/$path"
pdflatex -output-directory="$dest" "$dest/$file" -draftmode  # 1
pdflatex -output-directory="$dest" "$dest/$file" -draftmode  # 2 (line numbers)
pdflatex -output-directory="$dest" "$dest/$file"             # 3

# cleanup
rm -Rf "$temp"

