#!/usr/bin/env bash
#
# update-rss.sh — rebuild the site and update rss feed locally
#
# this script:
#   1. runs hugo to build the site into public/
#   2. verifies the rss feed was generated
#   3. shows a summary of the feed
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo "  update rss"
echo "  ----------"
echo ""

# --- check hugo is installed ---
if ! command -v hugo &> /dev/null; then
  echo "  error: hugo is not installed."
  echo "  install it from https://gohugo.io/installation/"
  echo ""
  exit 1
fi

# --- build the site ---
echo "  building site with hugo..."
hugo --minify --quiet

# --- check rss feed ---
RSS_FILE="public/blog.xml"

if [[ -f "$RSS_FILE" ]]; then
  ITEM_COUNT=$(grep -c '<item>' "$RSS_FILE" 2>/dev/null || echo "0")
  FEED_SIZE=$(wc -c < "$RSS_FILE" | xargs)
  echo "  ✓ rss feed generated: ${RSS_FILE}"
  echo "    ${ITEM_COUNT} item(s), ${FEED_SIZE} bytes"
else
  echo "  warning: rss feed not found at ${RSS_FILE}"
  echo "  check your hugo.toml [outputs] configuration."
fi

# --- check other outputs ---
echo ""

# count html files
HTML_COUNT=$(find public/ -name "*.html" | wc -l | xargs)
echo "  site built: ${HTML_COUNT} html pages in public/"

# check robots.txt
if [[ -f "public/robots.txt" ]]; then
  echo "  ✓ robots.txt generated"
fi

# check sitemap
if [[ -f "public/sitemap.xml" ]]; then
  echo "  ✓ sitemap.xml generated"
fi

echo ""
echo "  the public/ directory is ready for deployment."
echo "  push to main to trigger github actions, or serve locally:"
echo "    hugo server"
echo ""
