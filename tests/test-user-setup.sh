#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config_setup="$repo_root/files/system/usr/libexec/fedora-niri/config-setup"
nvim_source="$repo_root/files/system/usr/libexec/fedora-niri/nvim-setup"
fcitx_source="$repo_root/files/system/usr/libexec/fedora-niri/fcitx-setup"
init_script="$repo_root/files/system/usr/libexec/fedora-niri/init"
test_root="$(mktemp -d)"
trap 'rm -rf -- "$test_root"' EXIT

mock_bin="$test_root/bin"
mkdir -p "$mock_bin"

cat > "$mock_bin/git" <<'MOCK'
#!/usr/bin/env bash
set -Eeuo pipefail
case "${1:-}" in
  clone)
    destination="${@: -1}"
    mkdir -p "$destination/.git" "$destination/lua"
    printf 'return {}\n' > "$destination/init.lua"
    printf 'mock repository\n' > "$destination/.git/HEAD"
    printf 'mock config\n' > "$destination/lua/config.lua"
    ;;
  -C)
    exit 0
    ;;
  *)
    echo "Unexpected mock git arguments: $*" >&2
    exit 90
    ;;
esac
MOCK
chmod +x "$mock_bin/git"

# Exercise the actual Neovim setup with a mocked GitHub clone.
nvim_home="$test_root/nvim-home"
mkdir -p "$nvim_home/.config/nvim"
printf 'user original config\n' > "$nvim_home/.config/nvim/user.lua"
nvim_test="$test_root/nvim-setup"
sed "s|^source /usr/libexec/fedora-niri/config-setup$|source \"$config_setup\"|" "$nvim_source" > "$nvim_test"
HOME="$nvim_home" XDG_STATE_HOME="$test_root/nvim-state" PATH="$mock_bin:$PATH" bash "$nvim_test" --yes
[[ -s "$nvim_home/.config/nvim/init.lua" ]]
[[ -d "$nvim_home/.config/nvim/.git" ]]
[[ ! -e "$nvim_home/.config/nvim/user.lua" ]]
HOME="$nvim_home" XDG_STATE_HOME="$test_root/nvim-state" PATH="$mock_bin:$PATH" bash "$nvim_test" --uninstall --yes
[[ "$(cat "$nvim_home/.config/nvim/user.lua")" == "user original config" ]]
[[ ! -e "$nvim_home/.config/nvim/init.lua" ]]

# Mock the Fcitx5 daemon and its remote control interface.
export FCITX_RUNNING="$test_root/fcitx-running"
export FCITX_CURRENT="$test_root/fcitx-current"
cat > "$mock_bin/fcitx5" <<'MOCK'
#!/usr/bin/env bash
set -Eeuo pipefail
touch "$FCITX_RUNNING"
printf 'keyboard-us\n' > "$FCITX_CURRENT"
MOCK
cat > "$mock_bin/fcitx5-remote" <<'MOCK'
#!/usr/bin/env bash
set -Eeuo pipefail
case "${1:-}" in
  -e) rm -f -- "$FCITX_RUNNING" ;;
  -r) : ;;
  -s)
    [[ "${2:-}" == rime ]] || exit 91
    printf 'rime\n' > "$FCITX_CURRENT"
    ;;
  -n) cat "$FCITX_CURRENT" ;;
  *) echo "Unexpected mock fcitx5-remote arguments: $*" >&2; exit 92 ;;
esac
MOCK
cat > "$mock_bin/pgrep" <<'MOCK'
#!/usr/bin/env bash
[[ -f "$FCITX_RUNNING" ]]
MOCK
chmod +x "$mock_bin/fcitx5" "$mock_bin/fcitx5-remote" "$mock_bin/pgrep"

fcitx_home="$test_root/fcitx-home"
mkdir -p "$fcitx_home/.config/fcitx5"
cat > "$fcitx_home/.config/fcitx5/config" <<'CONFIG'
[Hotkey]
AltTriggerKeys=Shift_L
TriggerKeys=Control+space

[Behavior]
ActiveByDefault=True
CONFIG
cat > "$fcitx_home/.config/fcitx5/profile" <<'PROFILE'
[Groups/0]
Name=Original
DefaultIM=keyboard-us
PROFILE
fcitx_test="$test_root/fcitx-setup"
sed "s|^source /usr/libexec/fedora-niri/config-setup$|source \"$config_setup\"|" "$fcitx_source" > "$fcitx_test"
HOME="$fcitx_home" XDG_STATE_HOME="$test_root/fcitx-state" PATH="$mock_bin:$PATH" \
  FCITX_RUNNING="$FCITX_RUNNING" FCITX_CURRENT="$FCITX_CURRENT" bash "$fcitx_test" --yes

profile="$fcitx_home/.config/fcitx5/profile"
grep -Fqx 'DefaultIM=rime' "$profile"
rime_line="$(grep -n -m1 '^Name=rime$' "$profile" | cut -d: -f1)"
keyboard_line="$(grep -n -m1 '^Name=keyboard-us$' "$profile" | cut -d: -f1)"
(( rime_line < keyboard_line ))
[[ "$(cat "$FCITX_CURRENT")" == "rime" ]]
grep -Fqx 'GTK_IM_MODULE=fcitx' "$fcitx_home/.config/environment.d/90-fcitx5.conf"
grep -Fqx 'QT_IM_MODULE=fcitx' "$fcitx_home/.config/environment.d/90-fcitx5.conf"
grep -Fqx 'AltTriggerKeys=' "$fcitx_home/.config/fcitx5/config"
grep -Fqx 'TriggerKeys=Control+space' "$fcitx_home/.config/fcitx5/config"
grep -Fqx 'ActiveByDefault=True' "$fcitx_home/.config/fcitx5/config"
[[ -f "$fcitx_home/.local/share/fcitx5/rime/.git/HEAD" ]]

HOME="$fcitx_home" XDG_STATE_HOME="$test_root/fcitx-state" PATH="$mock_bin:$PATH" \
  FCITX_RUNNING="$FCITX_RUNNING" FCITX_CURRENT="$FCITX_CURRENT" bash "$fcitx_test" --uninstall --yes
grep -Fqx "AltTriggerKeys=Shift_L" "$fcitx_home/.config/fcitx5/config"
grep -Fqx "TriggerKeys=Control+space" "$fcitx_home/.config/fcitx5/config"
grep -Fqx "Name=Original" "$fcitx_home/.config/fcitx5/profile"
[[ ! -e "$fcitx_home/.local/share/fcitx5/rime" ]]
[[ ! -e "$fcitx_home/.config/environment.d/90-fcitx5.conf" ]]

# Fcitx remains an explicit Just action; it must not be wired into login init.
! grep -Fq 'run_setup fcitx-setup' "$init_script"
grep -Fq 'run_setup nvim-setup' "$init_script"

echo "PASS: LazyVim installation/restore and Fcitx5 Rime setup/restore."
