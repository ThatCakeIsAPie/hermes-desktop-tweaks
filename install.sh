#!/usr/bin/env bash
# Copy every plugin in this repo into the Hermes desktop-plugins folder.
# The desktop app watches that folder and hot-reloads each file it sees change.
# Symlinks are not an option: the app does not follow links in desktop-plugins/.
#
#   ./install.sh                 install or update all plugins
#   ./install.sh grokbot-tweaks  only the named ones
set -euo pipefail

here=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
dest="${HERMES_HOME:-$HOME/.hermes}/desktop-plugins"

if [ "$#" -gt 0 ]; then
  names=("$@")
else
  names=()
  for file in "$here"/*/plugin.js; do
    names+=("$(basename -- "$(dirname -- "$file")")")
  done
fi

for name in "${names[@]}"; do
  src="$here/$name/plugin.js"
  if [ ! -f "$src" ]; then
    echo "install.sh: no plugin named '$name' in this repo" >&2
    exit 1
  fi
  mkdir -p "$dest/$name"
  if cmp -s "$src" "$dest/$name/plugin.js" 2>/dev/null; then
    echo "$name: already up to date"
  else
    cp "$src" "$dest/$name/plugin.js"
    echo "$name: installed to $dest/$name/plugin.js"
  fi
done
