#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cleanup_source="$repo_root/files/system/usr/libexec/fedora-niri/cleanup"
logging_source="$repo_root/files/system/usr/libexec/fedora-niri/logging"
test_root="$(mktemp -d)"
trap 'rm -rf -- "$test_root"' EXIT

test_home="$test_root/home"
test_state="$test_root/state"
mkdir -p "$test_home" "$test_state/app-state" "$test_state/fedora-niri/upgrade-backups/test"
printf 'application state\n' > "$test_state/app-state/data"
printf 'recovery state\n' > "$test_state/fedora-niri/upgrade-backups/test/data"

test_cleanup="$test_root/cleanup"
sed "s|^source /usr/libexec/fedora-niri/logging$|source \"$logging_source\"|" "$cleanup_source" > "$test_cleanup"
chmod 0755 "$test_cleanup"

# Decline all cleanup prompts except the explicit state-data confirmation.
{
  for _ in {1..7}; do printf 'n\n'; done
  printf 'y\n'
  for _ in {1..4}; do printf 'n\n'; done
} | HOME="$test_home" XDG_STATE_HOME="$test_state" bash "$test_cleanup"

[[ ! -e "$test_state" ]] || {
  echo "ERROR: Explicitly confirmed state cleanup left data behind: $test_state" >&2
  exit 1
}

echo "PASS: cleanup removes the complete XDG state directory after explicit confirmation."
