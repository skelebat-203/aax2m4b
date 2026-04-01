#!/usr/bin/env bash
#
# aax2m4b_batch.sh
#
# Batch‑convert Audible .aax files to .m4b using ffmpeg and a known activation
# code. Strips all identifying metadata while preserving basic book info.
#
# Behaviour:
#   - Looks for .aax files in  ~/Music/audiobooks/aax
#   - Writes .m4b files into ~/Music/audiobooks/need_to_zip
#   - Uses activation bytes: 2adc3435
#   - Builds filenames from tags (author / series / title), with a length cap
#   - If the generated name is too long or empty, falls back to the .aax name
#   - Keeps only audio streams, drops images/extra data streams
#   - Removes all metadata, then re‑adds only: title, artist (author), album (series)

set -euo pipefail

###############################################################################
# Configuration
###############################################################################

# One‑time Audible activation bytes for your account
ACT="1abc2345"

# Input and output directories
SRC_DIR="$HOME/Music/audiobooks/aax"
DST_DIR="$HOME/Music/audiobooks/need_to_zip"

# Conservative maximum filename length (Linux/ext4 is 255 bytes; we stay lower)
MAX_NAME_LEN=200

mkdir -p "$DST_DIR"

###############################################################################
# Helpers
###############################################################################

# get_tag <file> <tag-key>
# Use ffprobe to extract a given metadata tag (artist/album/title).
get_tag() {
  local file="$1"
  local key="$2"
  ffprobe -v error \
          -show_entries "format_tags=$key" \
          -of default=nw=1:nk=1 \
          "$file" 2>/dev/null | head -n1
}

# sanitize
# Read a string on stdin and:
#   - convert whitespace to underscores
#   - remove characters unsafe for filenames
#   - collapse repeated underscores
sanitize() {
  sed -E 's/[ \t]+/_/g; s/[^A-Za-z0-9._-]+/_/g; s/_+/_/g; s/^_+//; s/_+$//'
}

# truncate_name <name>
# Truncate the given name to MAX_NAME_LEN characters if necessary.
truncate_name() {
  local name="$1"
  local len="${#name}"
  if (( len > MAX_NAME_LEN )); then
    echo "${name:0:MAX_NAME_LEN}"
  else
    echo "$name"
  fi
}

###############################################################################
# Main loop
###############################################################################

for inpath in "$SRC_DIR"/*.aax; do
  # Skip if no .aax files exist
  [ -e "$inpath" ] || continue

  base="$(basename "$inpath")"
  base_noext="${base%.aax}"

  # Raw tags (exactly as stored in the file) – used for metadata on output
  author_raw="$(get_tag "$inpath" artist)"   # treated as author
  series_raw="$(get_tag "$inpath" album)"    # treated as series
  title_raw="$(get_tag "$inpath" title)"     # treated as book title

  # Sanitized versions for filenames
  author="$(printf '%s' "$author_raw" | sanitize)"
  series="$(printf '%s' "$series_raw" | sanitize)"
  title="$(printf '%s' "$title_raw" | sanitize)"
  base_clean="$(printf '%s' "$base_noext" | sanitize)"

  # ---------------------------------------------------------------------------
  # Build filename according to priority rules:
  # 1. author + series + title
  # 2. author + title
  # 3. series + title
  # 4. author + series + original filename
  # 5. author + original filename
  # 6. series + original filename
  # 7. title only
  # 8. fallback: original filename
  # ---------------------------------------------------------------------------
  name=""
  if [[ -n "$author" && -n "$series" && -n "$title" ]]; then
    name="${author}_${series}_${title}"
  elif [[ -n "$author" && -n "$title" ]]; then
    name="${author}_${title}"
  elif [[ -n "$series" && -n "$title" ]]; then
    name="${series}_${title}"
  elif [[ -n "$author" && -n "$series" ]]; then
    name="${author}_${series}_${base_clean}"
  elif [[ -n "$author" ]]; then
    name="${author}_${base_clean}"
  elif [[ -n "$series" ]]; then
    name="${series}_${base_clean}"
  elif [[ -n "$title" ]]; then
    name="${title}"
  else
    name="${base_clean}"
  fi

  # Enforce filename length; if still bad/empty, fall back to base filename
  name="$(truncate_name "$name")"
  if [[ -z "$name" || "${#name}" -gt "$MAX_NAME_LEN" ]]; then
    name="$(truncate_name "$base_clean")"
  fi

  outpath="$DST_DIR/${name}.m4b"
  echo "Converting: $base  ->  $(basename "$outpath")"

  # ---------------------------------------------------------------------------
  # Convert:
  #   - Use activation bytes to decrypt AAX
  #   - Keep only audio streams (-map 0:a), drop images / text / data
  #   - Copy AAC audio without re‑encoding (-c:a copy)
  #   - Strip all metadata (-map_metadata -1)
  #   - Re‑add only book metadata (title, artist/author, album/series)
  # ---------------------------------------------------------------------------
  meta_args=()
  if [[ -n "$author_raw" ]]; then
    meta_args+=( -metadata "artist=$author_raw" )
  fi
  if [[ -n "$series_raw" ]]; then
    meta_args+=( -metadata "album=$series_raw" )
  fi
  if [[ -n "$title_raw" ]]; then
    meta_args+=( -metadata "title=$title_raw" )
  fi

  ffmpeg -y -activation_bytes "$ACT" \
    -i "$inpath" \
    -map 0:a \
    -vn \
    -c:a copy \
    -map_metadata -1 \
    "${meta_args[@]}" \
    "$outpath"

done

echo "Done. M4B files are in: $DST_DIR"