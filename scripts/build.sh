#!/usr/bin/env bash
# Builds datapack and resource pack zips into dist/.
# Usage: scripts/build.sh <version>   (e.g. 1.0.0)
# Output names: <pack>-<version>.<mc_version>.zip, mc_version is read from MC_VERSION.
set -euo pipefail

VERSION="${1:?usage: $0 <version>}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="$ROOT/dist"
MC_VERSION="$(tr -d '[:space:]' < "$ROOT/MC_VERSION")"
[[ -n "$MC_VERSION" ]] || { echo "error: MC_VERSION is empty" >&2; exit 1; }
SUFFIX="$VERSION.$MC_VERSION"

rm -rf "$DIST"
mkdir -p "$DIST"

build() {
  local src="$1" out="$2"
  if [[ ! -f "$ROOT/$src/pack.mcmeta" ]]; then
    echo "error: $src/pack.mcmeta missing" >&2
    exit 1
  fi
  # zip from inside the folder so pack.mcmeta sits at the archive root
  (cd "$ROOT/$src" && zip -q -X -r "$out" . -x '*.gitkeep' '*.DS_Store')
}

build datapack     "$DIST/datapack-$SUFFIX.zip"
build resourcepack "$DIST/resourcepack-$SUFFIX.zip"
# stable name for the public "latest" download URL
cp "$DIST/resourcepack-$SUFFIX.zip" "$DIST/resourcepack.zip"

(cd "$DIST" && sha1sum resourcepack.zip | cut -d' ' -f1 > resourcepack.zip.sha1)

echo "Built in $DIST:"
ls -1 "$DIST"
echo "resource pack sha1: $(cat "$DIST/resourcepack.zip.sha1")"
