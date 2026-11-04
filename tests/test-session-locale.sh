#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
greetd_config="$repo_root/files/system/etc/greetd/config.toml"
niri_session="$repo_root/files/system/usr/share/wayland-sessions/niri.desktop"

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
grep -Fqx 'Exec=env LANG=zh_CN.UTF-8 niri-session' "$niri_session"

echo "PASS: greetd and Niri session locale configuration."
