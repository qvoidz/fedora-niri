#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
greetd_config="$repo_root/files/system/etc/greetd/config.toml"
niri_session="$repo_root/files/system/usr/share/wayland-sessions/niri.desktop"
session_launcher="$repo_root/files/system/usr/libexec/fedora-niri/niri-session-launcher"

[[ -f "$greetd_config" ]] || {
  echo "ERROR: Image greetd configuration is missing." >&2
  exit 1
}
grep -Fqx '[general]' "$greetd_config"
grep -Fqx 'source_profile = false' "$greetd_config"
grep -Fqx 'user = "greeter"' "$greetd_config"
grep -Fqx 'command = "env LANG=zh_CN.UTF-8 dms-greeter --command niri"' "$greetd_config"

[[ -f "$niri_session" ]] || {
  echo "ERROR: Niri Wayland session entry is missing." >&2
  exit 1
}
grep -Fqx 'Exec=/usr/libexec/fedora-niri/niri-session-launcher' "$niri_session"

[[ -f "$session_launcher" ]] || {
  echo "ERROR: Niri session launcher is missing." >&2
  exit 1
}
grep -Fq 'set -gx LANG zh_CN.UTF-8; exec niri-session -l' "$session_launcher"
grep -Fq 'export LANG=zh_CN.UTF-8; exec niri-session -l' "$session_launcher"

echo "PASS: greetd and Niri session locale configuration."
