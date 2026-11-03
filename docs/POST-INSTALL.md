# Post-install notes

## DMS Greeter

The image includes `dms-greeter`, but does not enable it automatically. On Fedora Atomic, configure greetd and enable its service explicitly; do not rely on `dms-greeter install` or `dms-greeter enable`, which are disabled by the immutable-system policy.

For a Niri session, configure `/etc/greetd/config.toml` according to the installed DMS Greeter version and verify its documented command-line options before enabling `greetd.service`. Enabling greetd replaces the current display manager, so this remains an explicit deployment step.

## Rime Ice

The image seeds Rime Ice under `/etc/skel/.local/share/fcitx5/rime`, so newly created user accounts receive it automatically. Existing accounts are not overwritten; they can follow the upstream installation guide at <https://github.com/iDvel/rime-ice/blob/main/others/docs/Installation.md>.

## Flatpak applications

Tencent Meeting (`com.tencent.wemeet`), WeChat (`com.tencent.WeChat`), Visual Studio Code (`com.visualstudio.code`), Steam (`com.valvesoftware.Steam`) and Lutris (`net.lutris.Lutris`) are installed system-wide from Flathub.
