#!/usr/bin/env bash
#
# new-post.sh — create a blank markdown file for a new post
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo "  new post"
echo "  --------"
echo ""
read -rp "  post name: " NAME

if [[ -z "$NAME" ]]; then
  echo "  error: name cannot be empty."
  exit 1
fi

# generate slug
SLUG=$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
YEAR=$(date +%Y)

POST_DIR="content/blog/${YEAR}/${SLUG}"
POST_FILE="${POST_DIR}/index.md"

if [[ -f "$POST_FILE" ]]; then
  echo "  already exists: ${POST_FILE}"
  exit 1
fi

mkdir -p "$POST_DIR"
touch "$POST_FILE"

echo ""
echo "  created: ${POST_FILE}"
echo ""
echo "  just write your post in there, plain markdown."
echo "  run ./finalize.sh when youre done."
echo ""
