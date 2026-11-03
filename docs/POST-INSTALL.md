# Post-install notes

## DMS Greeter

The image includes `dms-greeter`, but does not enable it automatically. On Fedora Atomic, configure greetd and enable its service explicitly; do not rely on `dms-greeter install` or `dms-greeter enable`, which are disabled by the immutable-system policy.

For a Niri session, the greetd command is:

```toml
[terminal]
vt = 1

[default_session]
user = "greeter"
command = "dms-greeter --command niri"
```

Place this in `/etc/greetd/config.toml`, then enable `greetd.service`. Confirm that `getent passwd greeter` returns the greeter account; if it does not, reboot once so `systemd-sysusers` can create it.

## Tencent Meeting

Tencent Meeting is not included in the image recipe yet. Its official Linux download is provided through Tencent's download center, but the page currently does not expose a stable, version-independent RPM URL suitable for a reproducible BlueBuild recipe. Download the Fedora-compatible Linux package from <https://meeting.tencent.com/download/index.html> and install it locally after deployment.

## Rime Ice

The image seeds Rime Ice under `/etc/skel/.local/share/fcitx5/rime`, so newly created user accounts receive it automatically. Existing accounts are not overwritten; they can follow the upstream installation guide at <https://github.com/iDvel/rime-ice/blob/main/others/docs/Installation.md>.
