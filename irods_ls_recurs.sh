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

    # TSV output; we will parse by tab
    mapfile -t lines < <(gocmd ls -lH --output_tsv "$col")

    # Skip the initial collection header block:
    # iRODS Collection
    # Type    Path
    # collection   /path
    # Content of /path
    # Type    Name    Replica Owner   Replica Number  ...
    in_header=1
    for raw in "${lines[@]}"; do
        line="$raw"

        # Trim leading/trailing whitespace
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"

        [[ -z "$line" ]] && continue

        if (( in_header )); then
            # Detect end of header: the line starting with "Type<TAB>Name<TAB>Replica..."
            if [[ "$line" == $'Type\tName\tReplica Owner\tReplica Number\tResource Hierarchy\tSize\tModify Time\tStatus\tDescription'* ]]; then
                in_header=0
            fi
            continue
        fi

        # Now we are in the data section; fields are tab-separated:
        # Type  Name  Replica Owner  Replica Number  Resource Hierarchy  Size  Modify Time  Status  Description
        IFS=$'\t' read -r f_type f_name f_replica_owner f_replica_num \
            f_resource f_size f_mtime f_status f_desc <<<"$line"

        # Collections
        if [[ "$f_type" == "collection" ]]; then
            # Full absolute path of collection:
            abs_path="${col%/}/$f_name"

            # Relative path to ROOT
            rel="${abs_path#$ROOT/}"
            [[ "$rel" == "$ROOT" ]] && rel="."

            dir="$rel"
            name=""

            printf "C\tNA\t%s\t%s\tNA\tNA\n" \
                "$dir" "$name"

            queue+=("$abs_path")
            echo "  queued collection: $abs_path (rel: $rel)" >&2
            continue
        fi

        # Data objects
        if [[ "$f_type" == "data-object" ]]; then
            # Keep only replica 0
            [[ "$f_replica_num" != "0" ]] && continue

            owner="$f_replica_owner"
            size="$f_size"
            mtime="$f_mtime"

            abs_path="${col%/}/$f_name"

            # Relative path to ROOT
            rel="${abs_path#$ROOT/}"
            [[ "$rel" == "$ROOT" ]] && rel="."

            # Split rel into dir and base name
            if [[ "$rel" == */* ]]; then
                dir="${rel%/*}"
                base="${rel##*/}"
            else
                dir="."
                base="$rel"
            fi

            printf "D\t%s\t%s\t%s\t%s\t%s\n" \
                "$owner" "$dir" "$base" "$size" "$mtime"
        fi
    done
done
