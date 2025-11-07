#!/usr/bin/env bash
set -euo pipefail

VERSION_FILE="VERSION"

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <version> [--dry-run]"
  exit 1
fi

new_version="$1"

if ! [[ "$new_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Invalid version format: $new_version"
  echo "Expected format: x.y.z (e.g., 1.2.3)"
  exit 1
fi

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "Version file not found: $VERSION_FILE"
  exit 1
fi

echo "Bumping version to $new_version in $VERSION_FILE"
sed -i.bak -E 's/[0-9]+\.[0-9]+\.[0-9]+/'"$new_version"'/' "$VERSION_FILE"
rm -f "$VERSION_FILE.bak"

echo "Updated to version $new_version"
