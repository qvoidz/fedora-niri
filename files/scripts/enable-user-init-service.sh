#!/usr/bin/env bash
set -Eeuo pipefail
unit=fedora-niri-init.service
source=/usr/lib/systemd/user/$unit
target=/etc/systemd/user/default.target.wants/$unit
[[ -f "$source" ]] || { echo "ERROR: User service unit is missing: $source" >&2; exit 1; }
install -d -m 0755 "$(dirname "$target")"
ln -sfn "$source" "$target"
[[ -L "$target" ]] || { echo "ERROR: Failed to enable global user service: $unit" >&2; exit 1; }
echo "Fedora Niri user initialization service enabled successfully."
