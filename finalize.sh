#!/usr/bin/env bash
#
# finalize.sh — reads all posts, adds frontmatter if missing,
#               syncs to preview, rebuilds posts.js, syncs css
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo "  finalize"
echo "  --------"
echo ""

CONTENT_DIR="content/blog"
PREVIEW_POSTS="preview/posts"
POSTS_JS="preview/posts.js"
THEME_CSS="themes/minimal/static/css"
PREVIEW_CSS="preview/css"

mkdir -p "$PREVIEW_POSTS"
mkdir -p "$PREVIEW_CSS"

# --- collect all posts ---
declare -a ALL_SLUGS=()
declare -a ALL_DATES=()
declare -a ALL_TITLES=()
declare -a ALL_DESCRIPTIONS=()
POST_COUNT=0

if [[ ! -d "$CONTENT_DIR" ]]; then
  echo "  no content/blog/ directory found."
  exit 0
fi

while IFS= read -r -d '' md_file; do
  slug=$(basename "$(dirname "$md_file")")
  
  # skip _index.md or section files
  [[ "$slug" == "blog" ]] && continue
  [[ "$slug" == "content" ]] && continue

  raw=$(cat "$md_file")

  # check if file is empty
  if [[ -z "$(echo "$raw" | tr -d '[:space:]')" ]]; then
    echo "  ⊘ ${slug} — empty file, skipping"
    continue
  fi

  # check if frontmatter already exists
  has_frontmatter=false
  if echo "$raw" | head -1 | grep -q '^---$'; then
    has_frontmatter=true
  fi

  if [[ "$has_frontmatter" == true ]]; then
    # extract existing frontmatter values
    title=""
    date=""
    description=""
    in_fm=false
    fm_done=false

    while IFS= read -r line; do
      if [[ "$fm_done" == true ]]; then break; fi
      if [[ "$line" == "---" ]]; then
        if [[ "$in_fm" == true ]]; then
          fm_done=true
        else
          in_fm=true
        fi
        continue
      fi
      if [[ "$in_fm" == true ]]; then
        key=$(echo "$line" | cut -d: -f1 | xargs 2>/dev/null || true)
        val=$(echo "$line" | cut -d: -f2- | xargs 2>/dev/null || true)
        val=$(echo "$val" | sed 's/^"//;s/"$//')
        case "$key" in
          title) title="$val" ;;
          date) date="$val" ;;
          description) description="$val" ;;
        esac
      fi
    done <<< "$raw"

    # fill in missing fields
    changed=false

    if [[ -z "$title" ]]; then
      # try to get title from first # heading in body
      body=$(echo "$raw" | awk '/^---$/{c++;next}c>=2')
      heading=$(echo "$body" | grep -m1 '^# ' | sed 's/^# //' || true)
      if [[ -n "$heading" ]]; then
        title="$heading"
      else
        title="$slug"
      fi
      changed=true
    fi

    if [[ -z "$date" ]]; then
      # use file modification date
      date=$(date -r "$md_file" +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)
      changed=true
    fi

    if [[ -z "$description" ]]; then
      # grab first non-empty, non-heading line from body as description
      body=$(echo "$raw" | awk '/^---$/{c++;next}c>=2')
      description=$(echo "$body" | sed '/^$/d' | grep -v '^#' | grep -v '^```' | head -1 | cut -c1-150 || true)
      if [[ -z "$description" ]]; then
        description="$title"
      fi
      changed=true
    fi

    if [[ "$changed" == true ]]; then
      # rebuild the file with updated frontmatter
      body=$(echo "$raw" | awk '/^---$/{c++;next}c>=2')
      {
        echo "---"
        echo "title: \"${title}\""
        echo "date: ${date}"
        echo "description: \"${description}\""
        echo "---"
        echo ""
        echo "$body"
      } > "$md_file"
      echo "  ✓ ${slug} — updated frontmatter"
    else
      echo "  ✓ ${slug} — looks good"
    fi

  else
    # no frontmatter at all — generate everything from the content
    
    # try to find a title from the first # heading
    heading=$(echo "$raw" | grep -m1 '^# ' | sed 's/^# //' || true)
    if [[ -n "$heading" ]]; then
      title="$heading"
      # remove the heading line from body
      body=$(echo "$raw" | sed '0,/^# /{/^# /d}')
    else
      title="$slug"
      body="$raw"
    fi

    # date from file mtime
    date=$(date -r "$md_file" +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)

    # description from first real paragraph (skip blanks, headings, code fences)
    description=$(echo "$body" | sed '/^$/d' | grep -v '^#' | grep -v '^```' | head -1 | cut -c1-150 || true)
    if [[ -z "$description" ]]; then
      description="$title"
    fi

    # write the file with frontmatter prepended
    {
      echo "---"
      echo "title: \"${title}\""
      echo "date: ${date}"
      echo "description: \"${description}\""
      echo "---"
      echo ""
      echo "$body"
    } > "$md_file"

    echo "  ✓ ${slug} — added frontmatter"
  fi

  # store for posts.js
  ALL_SLUGS+=("$slug")
  ALL_DATES+=("$date")
  ALL_TITLES+=("$title")
  ALL_DESCRIPTIONS+=("$description")
  POST_COUNT=$((POST_COUNT + 1))

  # sync to preview
  cp "$md_file" "${PREVIEW_POSTS}/${slug}.md"

  # sync any images/assets from the post directory to preview root
  # so relative paths in markdown (like ![alt](image.png)) work locally
  find "$(dirname "$md_file")" -maxdepth 1 -type f ! -name "index.md" -exec cp {} "preview/" \;

done < <(find "$CONTENT_DIR" -name "index.md" -print0 | sort -z)

echo ""

if [[ $POST_COUNT -eq 0 ]]; then
  echo "  no posts found."
  cat > "$POSTS_JS" << 'EOF'
const POSTS = [
];
EOF
  cp "$THEME_CSS/main.css" "$PREVIEW_CSS/main.css"
  cp "$THEME_CSS/dark.css" "$PREVIEW_CSS/dark.css"
  # clean orphaned preview posts
  rm -f "$PREVIEW_POSTS"/*.md 2>/dev/null || true
  echo "  synced css, cleared posts.js"
  echo ""
  exit 0
fi

# --- sort posts by date (newest first) and rebuild posts.js ---
TMPFILE=$(mktemp "${SCRIPT_DIR}/.posts_sort_XXXXXX")
for i in "${!ALL_SLUGS[@]}"; do
  t_b64=$(echo -n "${ALL_TITLES[$i]}" | base64 -w 0)
  d_b64=$(echo -n "${ALL_DESCRIPTIONS[$i]}" | base64 -w 0)
  echo "${ALL_DATES[$i]}|${ALL_SLUGS[$i]}|$t_b64|$d_b64" >> "$TMPFILE"
done

SORTED=$(sort -r -t'|' -k1 "$TMPFILE")
rm -f "$TMPFILE"

{
  echo "const POSTS = ["
  while IFS='|' read -r pdate pslug t_b64 d_b64; do
    [[ -z "$pdate" ]] && continue
    ptitle=$(echo -n "$t_b64" | base64 -d)
    pdesc=$(echo -n "$d_b64" | base64 -d)
    echo "  {"
    echo "    slug: \"${pslug}\","
    echo "    file: \"posts/${pslug}.md\","
    echo "    date: \"${pdate}\","
    echo "    title: \"${ptitle//\"/\\\"}\","
    echo "    description: \"${pdesc//\"/\\\"}\","
    echo "  },"
  done <<< "$SORTED"
  echo "];"
} > "$POSTS_JS"

# --- sync css ---
cp "$THEME_CSS/main.css" "$PREVIEW_CSS/main.css"
cp "$THEME_CSS/dark.css" "$PREVIEW_CSS/dark.css"

# --- clean orphaned preview posts ---
for preview_file in "$PREVIEW_POSTS"/*.md; do
  [[ -f "$preview_file" ]] || continue
  preview_slug=$(basename "$preview_file" .md)
  found=false
  for s in "${ALL_SLUGS[@]}"; do
    if [[ "$s" == "$preview_slug" ]]; then
      found=true
      break
    fi
  done
  if [[ "$found" == false ]]; then
    rm "$preview_file"
    echo "  removed orphan: ${preview_slug}.md"
  fi
done

# ensure .nojekyll exists so github pages doesn't break markdown files
touch "$SCRIPT_DIR/.nojekyll"

echo "  done. ${POST_COUNT} post(s) finalized."
echo ""
echo "  preview: open preview/index.html in firefox"
echo "  or run: python3 -m http.server 8000"
echo "  deploy: git add . && git commit && git push"
echo ""
