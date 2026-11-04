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
  -l)
    if [[ -n "${FCITX_METHODS:-}" ]]; then
      printf '%s\n' "$FCITX_METHODS"
    else
      printf 'rime\nkeyboard-us\n'
    fi
    ;;
  -s)
    [[ "${2:-}" == rime ]] || exit 91
    printf 'rime\n' > "$FCITX_CURRENT"
    ;;
  -n) cat "$FCITX_CURRENT" ;;
  *) echo "Unexpected mock fcitx5-remote arguments: $*" >&2; exit 92 ;;
esac
MOCK
cat > "$mock_bin/rpm" <<'MOCK'
#!/usr/bin/env bash
[[ "${1:-}" == -q && "${2:-}" == fcitx5-rime ]]
MOCK
cat > "$mock_bin/pgrep" <<'MOCK'
#!/usr/bin/env bash
[[ -f "$FCITX_RUNNING" ]]
MOCK
chmod +x "$mock_bin/fcitx5" "$mock_bin/fcitx5-remote" "$mock_bin/rpm" "$mock_bin/pgrep"

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
grep -Fqx 'Default Layout=us' "$profile"
keyboard_line="$(grep -n -m1 '^Name=keyboard-us
[[ "$(cat "$FCITX_CURRENT")" == "rime" ]]
grep -Fqx 'GTK_IM_MODULE=fcitx' "$fcitx_home/.config/environment.d/90-fcitx5.conf"
grep -Fqx 'QT_IM_MODULE=fcitx' "$fcitx_home/.config/environment.d/90-fcitx5.conf"
grep -Fqx 'AltTriggerKeys=' "$fcitx_home/.config/fcitx5/config"
grep -Fqx 'TriggerKeys=Control+space' "$fcitx_home/.config/fcitx5/config"
grep -Fqx 'ActiveByDefault=True' "$fcitx_home/.config/fcitx5/config"
[[ -f "$fcitx_home/.local/share/fcitx5/rime/.git/HEAD" ]]
[[ -s "$test_root/fcitx-state/fedora-niri/logs/fcitx-setup.log" ]]
grep -Fq 'Fcitx5 input methods detected:' "$test_root/fcitx-state/fedora-niri/logs/fcitx-setup.log"

HOME="$fcitx_home" XDG_STATE_HOME="$test_root/fcitx-state" PATH="$mock_bin:$PATH" \
  FCITX_RUNNING="$FCITX_RUNNING" FCITX_CURRENT="$FCITX_CURRENT" bash "$fcitx_test" --uninstall --yes
grep -Fqx "AltTriggerKeys=Shift_L" "$fcitx_home/.config/fcitx5/config"
grep -Fqx "TriggerKeys=Control+space" "$fcitx_home/.config/fcitx5/config"
grep -Fqx "Name=Original" "$fcitx_home/.config/fcitx5/profile"
[[ ! -e "$fcitx_home/.local/share/fcitx5/rime" ]]
[[ ! -e "$fcitx_home/.config/environment.d/90-fcitx5.conf" ]]

# Custom XDG roots must be used and must participate in backup/restore.
xdg_home="$test_root/xdg-home"
xdg_config="$xdg_home/config"
xdg_data="$xdg_home/data"
mkdir -p "$xdg_home" "$xdg_config/fcitx5" "$xdg_config/environment.d"
printf 'custom-original-profile\\n' > "$xdg_config/fcitx5/profile"
printf 'CUSTOM_ENV=original\\n' > "$xdg_config/environment.d/90-fcitx5.conf"
HOME="$xdg_home" XDG_CONFIG_HOME="$xdg_config" XDG_DATA_HOME="$xdg_data" \
  XDG_STATE_HOME="$test_root/xdg-state" PATH="$mock_bin:$PATH" \
  FCITX_RUNNING="$FCITX_RUNNING" FCITX_CURRENT="$FCITX_CURRENT" \
  bash "$fcitx_test" --yes
[[ -f "$xdg_config/fcitx5/profile" ]]
[[ -f "$xdg_config/environment.d/90-fcitx5.conf" ]]
[[ -f "$xdg_data/fcitx5/rime/.git/HEAD" ]]
[[ ! -e "$xdg_home/.config/fcitx5/profile" ]]
HOME="$xdg_home" XDG_CONFIG_HOME="$xdg_config" XDG_DATA_HOME="$xdg_data" \
  XDG_STATE_HOME="$test_root/xdg-state" PATH="$mock_bin:$PATH" \
  FCITX_RUNNING="$FCITX_RUNNING" FCITX_CURRENT="$FCITX_CURRENT" \
  bash "$fcitx_test" --uninstall --yes
[[ "$(cat "$xdg_config/fcitx5/profile")" == "custom-original-profile" ]]
[[ "$(cat "$xdg_config/environment.d/90-fcitx5.conf")" == "CUSTOM_ENV=original" ]]
[[ ! -e "$xdg_data/fcitx5/rime" ]]

# Fcitx remains an explicit Just action; it must not be wired into login init.
! grep -Fq 'run_setup fcitx-setup' "$init_script"
grep -Fq 'run_setup nvim-setup' "$init_script"

# A profile entry must not be treated as proof that the Rime engine exists.
missing_rime_home="$test_root/missing-rime-home"
mkdir -p "$missing_rime_home"
set +e
HOME="$missing_rime_home" XDG_STATE_HOME="$test_root/missing-rime-state" PATH="$mock_bin:$PATH" \
  FCITX_RUNNING="$FCITX_RUNNING" FCITX_CURRENT="$FCITX_CURRENT" FCITX_METHODS=keyboard-us \
  bash "$fcitx_test" --yes
missing_rime_status=$?
set -e
[[ "$missing_rime_status" -ne 0 ]]
grep -Fq 'Rime engine is not registered' "$test_root/missing-rime-state/fedora-niri/logs/fcitx-setup.log"


echo "PASS: LazyVim installation/restore and Fcitx5 Rime setup/restore."
 "$profile" | cut -d: -f1)"
rime_line="$(grep -n -m1 '^Name=rime
[[ "$(cat "$FCITX_CURRENT")" == "rime" ]]
grep -Fqx 'GTK_IM_MODULE=fcitx' "$fcitx_home/.config/environment.d/90-fcitx5.conf"
grep -Fqx 'QT_IM_MODULE=fcitx' "$fcitx_home/.config/environment.d/90-fcitx5.conf"
grep -Fqx 'AltTriggerKeys=' "$fcitx_home/.config/fcitx5/config"
grep -Fqx 'TriggerKeys=Control+space' "$fcitx_home/.config/fcitx5/config"
grep -Fqx 'ActiveByDefault=True' "$fcitx_home/.config/fcitx5/config"
[[ -f "$fcitx_home/.local/share/fcitx5/rime/.git/HEAD" ]]
[[ -s "$test_root/fcitx-state/fedora-niri/logs/fcitx-setup.log" ]]
grep -Fq 'Fcitx5 input methods detected:' "$test_root/fcitx-state/fedora-niri/logs/fcitx-setup.log"

HOME="$fcitx_home" XDG_STATE_HOME="$test_root/fcitx-state" PATH="$mock_bin:$PATH" \
  FCITX_RUNNING="$FCITX_RUNNING" FCITX_CURRENT="$FCITX_CURRENT" bash "$fcitx_test" --uninstall --yes
grep -Fqx "AltTriggerKeys=Shift_L" "$fcitx_home/.config/fcitx5/config"
grep -Fqx "TriggerKeys=Control+space" "$fcitx_home/.config/fcitx5/config"
grep -Fqx "Name=Original" "$fcitx_home/.config/fcitx5/profile"
[[ ! -e "$fcitx_home/.local/share/fcitx5/rime" ]]
[[ ! -e "$fcitx_home/.config/environment.d/90-fcitx5.conf" ]]

# Custom XDG roots must be used and must participate in backup/restore.
xdg_home="$test_root/xdg-home"
xdg_config="$xdg_home/config"
xdg_data="$xdg_home/data"
mkdir -p "$xdg_home" "$xdg_config/fcitx5" "$xdg_config/environment.d"
printf 'custom-original-profile\\n' > "$xdg_config/fcitx5/profile"
printf 'CUSTOM_ENV=original\\n' > "$xdg_config/environment.d/90-fcitx5.conf"
HOME="$xdg_home" XDG_CONFIG_HOME="$xdg_config" XDG_DATA_HOME="$xdg_data" \
  XDG_STATE_HOME="$test_root/xdg-state" PATH="$mock_bin:$PATH" \
  FCITX_RUNNING="$FCITX_RUNNING" FCITX_CURRENT="$FCITX_CURRENT" \
  bash "$fcitx_test" --yes
[[ -f "$xdg_config/fcitx5/profile" ]]
[[ -f "$xdg_config/environment.d/90-fcitx5.conf" ]]
[[ -f "$xdg_data/fcitx5/rime/.git/HEAD" ]]
[[ ! -e "$xdg_home/.config/fcitx5/profile" ]]
HOME="$xdg_home" XDG_CONFIG_HOME="$xdg_config" XDG_DATA_HOME="$xdg_data" \
  XDG_STATE_HOME="$test_root/xdg-state" PATH="$mock_bin:$PATH" \
  FCITX_RUNNING="$FCITX_RUNNING" FCITX_CURRENT="$FCITX_CURRENT" \
  bash "$fcitx_test" --uninstall --yes
[[ "$(cat "$xdg_config/fcitx5/profile")" == "custom-original-profile" ]]
[[ "$(cat "$xdg_config/environment.d/90-fcitx5.conf")" == "CUSTOM_ENV=original" ]]
[[ ! -e "$xdg_data/fcitx5/rime" ]]

# Fcitx remains an explicit Just action; it must not be wired into login init.
! grep -Fq 'run_setup fcitx-setup' "$init_script"
grep -Fq 'run_setup nvim-setup' "$init_script"

# A profile entry must not be treated as proof that the Rime engine exists.
missing_rime_home="$test_root/missing-rime-home"
mkdir -p "$missing_rime_home"
set +e
HOME="$missing_rime_home" XDG_STATE_HOME="$test_root/missing-rime-state" PATH="$mock_bin:$PATH" \
  FCITX_RUNNING="$FCITX_RUNNING" FCITX_CURRENT="$FCITX_CURRENT" FCITX_METHODS=keyboard-us \
  bash "$fcitx_test" --yes
missing_rime_status=$?
set -e
[[ "$missing_rime_status" -ne 0 ]]
grep -Fq 'Rime engine is not registered' "$test_root/missing-rime-state/fedora-niri/logs/fcitx-setup.log"


echo "PASS: LazyVim installation/restore and Fcitx5 Rime setup/restore."
 "$profile" | cut -d: -f1)"
(( keyboard_line < rime_line ))
[[ "$(cat "$FCITX_CURRENT")" == "rime" ]]
grep -Fqx 'GTK_IM_MODULE=fcitx' "$fcitx_home/.config/environment.d/90-fcitx5.conf"
grep -Fqx 'QT_IM_MODULE=fcitx' "$fcitx_home/.config/environment.d/90-fcitx5.conf"
grep -Fqx 'AltTriggerKeys=' "$fcitx_home/.config/fcitx5/config"
grep -Fqx 'TriggerKeys=Control+space' "$fcitx_home/.config/fcitx5/config"
grep -Fqx 'ActiveByDefault=True' "$fcitx_home/.config/fcitx5/config"
[[ -f "$fcitx_home/.local/share/fcitx5/rime/.git/HEAD" ]]
[[ -s "$test_root/fcitx-state/fedora-niri/logs/fcitx-setup.log" ]]
grep -Fq 'Fcitx5 input methods detected:' "$test_root/fcitx-state/fedora-niri/logs/fcitx-setup.log"

HOME="$fcitx_home" XDG_STATE_HOME="$test_root/fcitx-state" PATH="$mock_bin:$PATH" \
  FCITX_RUNNING="$FCITX_RUNNING" FCITX_CURRENT="$FCITX_CURRENT" bash "$fcitx_test" --uninstall --yes
grep -Fqx "AltTriggerKeys=Shift_L" "$fcitx_home/.config/fcitx5/config"
grep -Fqx "TriggerKeys=Control+space" "$fcitx_home/.config/fcitx5/config"
grep -Fqx "Name=Original" "$fcitx_home/.config/fcitx5/profile"
[[ ! -e "$fcitx_home/.local/share/fcitx5/rime" ]]
[[ ! -e "$fcitx_home/.config/environment.d/90-fcitx5.conf" ]]

# Custom XDG roots must be used and must participate in backup/restore.
xdg_home="$test_root/xdg-home"
xdg_config="$xdg_home/config"
xdg_data="$xdg_home/data"
mkdir -p "$xdg_home" "$xdg_config/fcitx5" "$xdg_config/environment.d"
printf 'custom-original-profile\\n' > "$xdg_config/fcitx5/profile"
printf 'CUSTOM_ENV=original\\n' > "$xdg_config/environment.d/90-fcitx5.conf"
HOME="$xdg_home" XDG_CONFIG_HOME="$xdg_config" XDG_DATA_HOME="$xdg_data" \
  XDG_STATE_HOME="$test_root/xdg-state" PATH="$mock_bin:$PATH" \
  FCITX_RUNNING="$FCITX_RUNNING" FCITX_CURRENT="$FCITX_CURRENT" \
  bash "$fcitx_test" --yes
[[ -f "$xdg_config/fcitx5/profile" ]]
[[ -f "$xdg_config/environment.d/90-fcitx5.conf" ]]
[[ -f "$xdg_data/fcitx5/rime/.git/HEAD" ]]
[[ ! -e "$xdg_home/.config/fcitx5/profile" ]]
HOME="$xdg_home" XDG_CONFIG_HOME="$xdg_config" XDG_DATA_HOME="$xdg_data" \
  XDG_STATE_HOME="$test_root/xdg-state" PATH="$mock_bin:$PATH" \
  FCITX_RUNNING="$FCITX_RUNNING" FCITX_CURRENT="$FCITX_CURRENT" \
  bash "$fcitx_test" --uninstall --yes
[[ "$(cat "$xdg_config/fcitx5/profile")" == "custom-original-profile" ]]
[[ "$(cat "$xdg_config/environment.d/90-fcitx5.conf")" == "CUSTOM_ENV=original" ]]
[[ ! -e "$xdg_data/fcitx5/rime" ]]

# Fcitx remains an explicit Just action; it must not be wired into login init.
! grep -Fq 'run_setup fcitx-setup' "$init_script"
grep -Fq 'run_setup nvim-setup' "$init_script"

# A profile entry must not be treated as proof that the Rime engine exists.
missing_rime_home="$test_root/missing-rime-home"
mkdir -p "$missing_rime_home"
set +e
HOME="$missing_rime_home" XDG_STATE_HOME="$test_root/missing-rime-state" PATH="$mock_bin:$PATH" \
  FCITX_RUNNING="$FCITX_RUNNING" FCITX_CURRENT="$FCITX_CURRENT" FCITX_METHODS=keyboard-us \
  bash "$fcitx_test" --yes
missing_rime_status=$?
set -e
[[ "$missing_rime_status" -ne 0 ]]
grep -Fq 'Rime engine is not registered' "$test_root/missing-rime-state/fedora-niri/logs/fcitx-setup.log"


echo "PASS: LazyVim installation/restore and Fcitx5 Rime setup/restore."
