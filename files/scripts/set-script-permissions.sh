#!/usr/bin/env bash
set -Eeuo pipefail
directory=/usr/libexec/fedora-niri
[[ -d "$directory" ]] || { echo "ERROR: Fedora Niri script directory is missing: $directory" >&2; exit 1; }
find "$directory" -maxdepth 1 -type f -exec chmod 0755 {} +
[[ -x "$directory/init" ]] || { echo "ERROR: Initialization entry point is not executable." >&2; exit 1; }
echo "Fedora Niri user scripts are executable."
