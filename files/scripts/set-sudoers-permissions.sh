#!/usr/bin/env bash
set -Eeuo pipefail
file=/etc/sudoers.d/99-wheel-nopasswd
[[ -f "$file" ]] || { echo "ERROR: Missing sudoers drop-in: $file" >&2; exit 1; }
chmod 0440 "$file"
visudo -cf /etc/sudoers
echo "Passwordless wheel sudo policy installed and validated successfully."
