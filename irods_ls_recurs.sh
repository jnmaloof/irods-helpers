#!/usr/bin/env bash
set -euo pipefail

# Usage: ./irods_inventory.sh [IRODS_ROOT]
ROOT="${1:-/iplant/home/shared/ucd.plantbio/maloof.lab/members/julin}"

# Normalize ROOT (no trailing slash, except if it's just "/")
ROOT="${ROOT%/}"
[[ -z "$ROOT" ]] && ROOT="/"

printf "type\towner\tdir\tname\tsize\ttime\n"

queue=("$ROOT")

while ((${#queue[@]})); do
    col="${queue[0]}"
    queue=("${queue[@]:1}")

    echo "### Visiting: $col" >&2

    mapfile -t lines < <(gocmd ls -lH "$col")

    for line in "${lines[@]}"; do
        # Trim leading/trailing whitespace
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"

        [[ -z "$line" ]] && continue
        [[ "$line" == "$col:" ]] && continue

        # Collections: lines starting with "C- "
        if [[ "$line" == C-\ * ]]; then
            abs_path="${line#C- }"

            # Relative path to ROOT
            rel="${abs_path#$ROOT/}"
            [[ "$rel" == "$ROOT" ]] && rel="."

            # Split rel into dir + name; for collections, treat rel as dir, empty name
            dir="$rel"
            name=""

            printf "C\tNA\t%s\t%s\tNA\tNA\n" "$dir" "$name"
            queue+=("$abs_path")
            echo "  queued collection: $abs_path (rel: $rel)" >&2
            continue
        fi

        # Files:
        # owner  replica  resource  size_num  size_unit  mtime  status  name
        read -r owner replica resource size_num size_unit mtime status name <<<"$line" || continue

        # Keep only replica 0
        [[ "$replica" != "0" ]] && continue

        size="${size_num} ${size_unit}"
        abs_path="${col%/}/$name"

        # Relative path to ROOT
        rel="${abs_path#$ROOT/}"
        [[ "$rel" == "$ROOT" ]] && rel="."

        # Split rel into dir and base name
        # If rel has no '/', dir=".", name=rel
        if [[ "$rel" == */* ]]; then
            dir="${rel%/*}"
            base="${rel##*/}"
        else
            dir="."
            base="$rel"
        fi

        # type owner dir name size time
        printf "D\t%s\t%s\t%s\t%s\t%s\n" \
            "$owner" "$dir" "$base" "$size" "$mtime"
    done
done
