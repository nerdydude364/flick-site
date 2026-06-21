#!/usr/bin/env bash
set -euo pipefail

RELEASE_URL="https://github.com/nerdydude364/flick/releases/latest"
REPO="nerdydude364/flick"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="$SCRIPT_DIR/release"
INDEX_HTML="$SCRIPT_DIR/index.html"

mkdir -p "$OUT_DIR"

echo "Resolving latest release..."
final_url="$(curl -fsSL -o /dev/null -w '%{url_effective}' "$RELEASE_URL")"
tag="${final_url##*/}"
echo "Latest release: $tag ($final_url)"

echo "Updating version badge in index.html..."
sed "s|<span class=\"version-badge\">[^<]*</span>|<span class=\"version-badge\">$tag</span>|" \
  "$INDEX_HTML" > "$INDEX_HTML.tmp" && mv "$INDEX_HTML.tmp" "$INDEX_HTML"

echo "Fetching asset list..."
release_json="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/tags/$tag")"

asset_urls="$(
  printf '%s' "$release_json" | grep -o '"browser_download_url": "[^"]*"' | sed 's/"browser_download_url": "//;s/"$//'
)"

if [[ -z "$asset_urls" ]]; then
  echo "No release assets found for $tag" >&2
  exit 1
fi

echo "Clearing old assets in $OUT_DIR..."
find "$OUT_DIR" -mindepth 1 ! -name '.gitkeep' -delete

count="$(printf '%s\n' "$asset_urls" | grep -c . || true)"
echo "Downloading $count asset(s)..."
while IFS= read -r url; do
  [[ -z "$url" ]] && continue
  filename="${url##*/}"
  echo "  -> $filename"
  curl -fsSL -o "$OUT_DIR/$filename" "$url"
done <<< "$asset_urls"

echo "Done. Assets saved to $OUT_DIR/"
