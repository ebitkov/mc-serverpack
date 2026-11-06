#!/usr/bin/env bash
# Deploys a built release (dist/) to an exaroton server via https://developers.exaroton.com.
# Usage: EXAROTON_TOKEN=... EXAROTON_SERVER_ID=... scripts/deploy-exaroton.sh <version>
#
# 1. uploads the datapack as <level-name>/datapacks/mc-serverpack.zip (stable name, overwrites the old one)
# 2. sets resource-pack-sha1 in server.properties to dist/resourcepack.zip.sha1
# 3. restarts the server if it is online, so both changes take effect
set -euo pipefail

VERSION="${1:?usage: $0 <version>}"
: "${EXAROTON_TOKEN:?EXAROTON_TOKEN is not set}"
: "${EXAROTON_SERVER_ID:?EXAROTON_SERVER_ID is not set}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="$ROOT/dist"
API="https://api.exaroton.com/v1/servers/$EXAROTON_SERVER_ID"
DATAPACK_NAME="mc-serverpack.zip"

shopt -s nullglob
DATAPACKS=("$DIST"/datapack-*.zip)
[[ ${#DATAPACKS[@]} -eq 1 ]] || { echo "error: expected exactly one dist/datapack-*.zip, found ${#DATAPACKS[@]}" >&2; exit 1; }
DATAPACK="${DATAPACKS[0]}"
SHA1="$(tr -d '[:space:]' < "$DIST/resourcepack.zip.sha1")"

# api <method> <path> [curl args...] -> prints .data, fails on HTTP or API errors
api() {
  local method="$1" path="$2"; shift 2
  local body
  body="$(curl -sS --fail-with-body -X "$method" -H "Authorization: Bearer $EXAROTON_TOKEN" "$@" "$API$path")" || {
    echo "error: $method $path failed: $body" >&2; exit 1
  }
  if [[ "$(jq -r '.success' <<<"$body")" != "true" ]]; then
    echo "error: $method $path: $(jq -r '.error' <<<"$body")" >&2; exit 1
  fi
  jq -c '.data' <<<"$body"
}

# config value from a ConfigFileOption array
config_value() { jq -r --arg k "$2" '.[] | select(.key == $k) | .value' <<<"$1"; }

PROPS="$(api GET /files/config/server.properties/)"
LEVEL="$(config_value "$PROPS" level-name)"
LEVEL="${LEVEL:-world}"
echo "World folder: $LEVEL"

echo "Uploading $(basename "$DATAPACK") -> $LEVEL/datapacks/$DATAPACK_NAME"
api PUT "/files/data/$LEVEL/datapacks/$DATAPACK_NAME/" \
  -H "Content-Type: application/octet-stream" --data-binary "@$DATAPACK" >/dev/null

echo "Setting resource-pack-sha1=$SHA1"
PROPS="$(api POST /files/config/server.properties/ \
  -H "Content-Type: application/json" --data "$(jq -n --arg v "$SHA1" '{"resource-pack-sha1": $v}')")"
if [[ "$(config_value "$PROPS" resource-pack-sha1)" != "$SHA1" ]]; then
  echo "error: resource-pack-sha1 was not updated (exaroton returned: $(config_value "$PROPS" resource-pack-sha1))" >&2
  exit 1
fi

STATUS="$(api GET "" | jq -r '.status')"
if [[ "$STATUS" == "1" ]]; then
  echo "Server is online, restarting"
  api POST /command/ -H "Content-Type: application/json" \
    --data "$(jq -n --arg c "say Updating server pack to $VERSION, restarting now..." '{command: $c}')" >/dev/null
  api GET /restart/ >/dev/null
else
  echo "Server status is $STATUS (not online), changes apply on next start"
fi

echo "Deployed $VERSION"
