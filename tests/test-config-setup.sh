#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config_setup="$repo_root/files/system/usr/libexec/fedora-niri/config-setup"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

export HOME="$test_root/home"
export XDG_STATE_HOME="$test_root/state"
export CONFIG_SETUP="$config_setup"
mkdir -p "$HOME/.config/demo"
printf 'original\n' > "$HOME/.config/demo/value"

module="$test_root/demo-setup"
cat > "$module" <<'MODULE'
#!/usr/bin/env bash
set -Eeuo pipefail
source "$CONFIG_SETUP"
paths_for() { printf '%s\n' '.config/demo'; }
do_install() {
  printf '%s\n' "$CONTENT" > "$home/.config/demo/value"
  [[ "${FAIL_INSTALL:-0}" != 1 ]] || return 42
}
config_setup_main demo "$@"
MODULE
chmod 0755 "$module"

assert_content() {
  local expected="$1" actual
  actual="$(cat "$HOME/.config/demo/value")"
  [[ "$actual" == "$expected" ]] || {
    printf 'Expected %q, got %q\n' "$expected" "$actual" >&2
    exit 1
  }
}

# First install must preserve the original user configuration.
CONTENT=installed bash "$module" --yes
assert_content installed
state="$XDG_STATE_HOME/fedora-niri/config-setup/demo"
[[ -f "$state/installed" && -f "$state/manifest" ]]

# A successful refresh must use a transaction snapshot of the pre-refresh state.
printf 'before-refresh\n' > "$HOME/.config/demo/value"
CONTENT=refreshed bash "$module" --refresh --yes
assert_content refreshed

# A failed refresh must restore the exact state from before that refresh.
set +e
CONTENT=broken FAIL_INSTALL=1 bash "$module" --refresh --yes
status=$?
set -e
[[ "$status" -eq 42 ]] || {
  echo "Expected failed refresh exit code 42, got $status" >&2
  exit 1
}
assert_content refreshed
[[ -f "$state/installed" && -f "$state/failed" && -f "$state/refresh-transaction/manifest" ]]

# A normal setup invocation must recover the failed transaction before its installed check.
CONTENT=must-not-run bash "$module" --yes
assert_content refreshed
[[ ! -f "$state/failed" && ! -d "$state/refresh-transaction" ]]

# Uninstall must restore the original pre-install configuration.
bash "$module" --uninstall --yes
assert_content original
[[ ! -e "$state" ]]

echo "PASS: config-setup install, refresh, failed-refresh recovery, and uninstall."
