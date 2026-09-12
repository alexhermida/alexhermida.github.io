#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
HUGO_BIN=${HUGO_BIN:-hugo}
EXPECTED_HUGO_VERSION=${EXPECTED_HUGO_VERSION:-0.166.0}
BUILD_DIR=$(mktemp -d "${TMPDIR:-/tmp}/blog-build.XXXXXX")
trap 'rm -rf "$BUILD_DIR"' EXIT

cd "$ROOT_DIR"

actual_version=$($HUGO_BIN version | sed -E 's/^hugo v([^+ ]+).*/\1/')
if [[ "${actual_version%%-*}" != "$EXPECTED_HUGO_VERSION" ]]; then
  echo "error: Hugo $EXPECTED_HUGO_VERSION is required (found $actual_version)" >&2
  echo "Set HUGO_BIN to a Hugo $EXPECTED_HUGO_VERSION executable." >&2
  exit 1
fi

"$HUGO_BIN" --minify --gc --destination "$BUILD_DIR"

required_files=(
  index.html
  about/index.html
  posts/index.html
  talks/index.html
  tags/index.html
  categories/index.html
  index.xml
  sitemap.xml
  robots.txt
  404.html
  CNAME
)

for file in "${required_files[@]}"; do
  if [[ ! -s "$BUILD_DIR/$file" ]]; then
    echo "error: missing or empty generated file: $file" >&2
    exit 1
  fi
done

if grep -RIl --include='*.html' -E '(href|src)=[^ >]*/blog/' "$BUILD_DIR" >/dev/null; then
  echo "error: generated HTML contains an asset or link rooted at /blog/" >&2
  exit 1
fi

if grep -RIl --include='*.html' -E 'https://alexhermida\.dev/blog/' "$BUILD_DIR" >/dev/null; then
  echo "error: generated HTML contains a canonical URL under /blog/" >&2
  exit 1
fi

stylesheet=$(grep -Eo 'href=/?assets/css/[^ >]+\.css' "$BUILD_DIR/index.html" | head -1 | sed -E 's/^href=//')
stylesheet=${stylesheet#/}
if [[ -z "$stylesheet" || ! -s "$BUILD_DIR/$stylesheet" ]]; then
  echo "error: home page stylesheet was not generated: ${stylesheet:-<not found>}" >&2
  exit 1
fi

if [[ $(<"$BUILD_DIR/CNAME") != "alexhermida.dev" ]]; then
  echo "error: generated CNAME is not alexhermida.dev" >&2
  exit 1
fi

if ! grep -q '<link rel=canonical href=https://alexhermida.dev/' "$BUILD_DIR/index.html"; then
  echo "error: home page canonical URL is not the production root" >&2
  exit 1
fi

echo "Site validation passed with Hugo $actual_version."
