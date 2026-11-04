# 安装后说明

## 脚本布局

功能脚本集中在 `/usr/libexec/fedora-niri/`，每个 Just 命令对应一个独立脚本；全局命令入口统一放在 `/usr/share/fedora-niri/Justfile`。`config-setup` 只提供通用的备份、恢复、安装状态、交互和失败回滚机制；字体、Kitty、DMS、Fcitx5 和 Neovim 的具体操作分别实现在各自的 `*-setup` 脚本中。`cleanup` 和 `user-dirs` 是独立脚本，不依赖配置管理核心。

## 普通 Just 命令

镜像使用普通 `just` 和全局 Justfile，不依赖 `ujust` 或 `blujust`。运行 `just` 查看任务列表。

| 命令 | 说明 |
| --- | --- |
| `just dms-setup` | Install/Uninstall/Cancel；安装时调用 `duxinstall -c niri -t kitty --all-features --exclude-deps dux-files --replace-configs niri,kitty -y`，启用全部 Dux 可选组件但明确排除 Dux Files |
| `just kitty-setup` | 管理 Kitty 配置 |
| `just fcitx-setup` | 管理 Fcitx5、Rime 和雾凇拼音用户配置 |
| `just fonts-setup` | 设置 DMS 默认界面字体（`fontFamily`），不修改 Kitty 字体 |
| `just nvim-setup` | 管理 LazyVim Starter |
| `just user-dirs` | 固定英文 XDG 用户目录 |
| `just cleanup` | 逐项选择要清理的用户数据 |
| `just cleanup -y` | 自动确认并删除所有清理类别 |

配置安装会先备份模块管理的目标；卸载时删除目标当前内容并恢复备份。`fonts-setup` 仅修改 `~/.config/DankMaterialShell/settings.json` 中的 `fontFamily`，不会修改 `monoFontFamily` 或 Kitty 配置；卸载时恢复原始 DMS 设置文件。DMS 在启动 duxinstall 前备份 Niri、Quickshell 和 DMS 配置目录。请注意，卸载会恢复这些目录的安装前快照，安装后在这些目录里新增的个人修改也会被覆盖。

## cleanup 清理说明

运行 `just cleanup` 时，脚本会分别询问是否删除以下内容；提示为 `[Y/n]`，输入 `n` 或 `no` 才会保留，直接回车默认为确认删除：

- 用户配置：`~/.config` 和常见 Shell、Git、Vim 配置文件。
- 缓存：`~/.cache`。
- 用户应用数据：`~/.local/share` 中除 Flatpak 外的数据、`~/.local/state`、`~/.var/app`。
- XDG 用户目录：桌面、文档、下载、图片、音乐、视频、公共、模板目录。
- HOME 中其他个人文件和隐藏目录：包括可能存在的 SSH/GPG 密钥、浏览器数据及其他应用配置。
- 用户级 Flatpak：卸载当前用户安装的 Flatpak 应用并删除其数据。

`just cleanup -- -y` 会将 `-y` 参数传递给清理脚本，跳过所有问题并直接执行以上全部清理类别。它可能删除 HOME 中几乎所有个人数据和密钥，且不可撤销；使用前务必备份。无论是否使用 `-y`，都不会删除系统级 Flatpak、RPM、系统镜像或其他用户的数据。不要在不确定时使用 `-y`。

## 英文 XDG 用户目录

运行 `just user-dirs` 后，文档、下载、图片、音乐、视频、桌面、模板和公共目录将使用英文名称。命令更新 `~/.config/user-dirs.dirs`，并禁用按 locale 自动翻译目录名。若旧中文目录与目标英文目录同时存在，脚本会保留两者并提示，不会擅自合并。

## DMS 检查

```bash
dms --help
dms version
systemctl --user status dms
journalctl --user -u dms -b
```

DMS 配置通过 `duxinstall -c niri -t kitty --all-features --exclude-deps dux-files --replace-configs niri,kitty -y` 安装；这里不使用在当前不可变系统上会失败的 `dms setup`。`--all-features` 会启用 Dux Greeter、Dux Search、Dux Calendar 和 Dux Files，因此必须同时使用 `--exclude-deps dux-files`，以保留 Nautilus 作为文件管理器。

## DMS 可选功能

| 组件 | 用途 | 启用方式 |
| --- | --- | --- |
| `danksearch`（命令 `dsearch`） | 文件名/内容搜索 | `systemctl --user enable --now dsearch`，首次运行 `dsearch index generate` |
| `dgop` | 系统资源数据 | DMS 小组件读取 |
| `cava` | 音频频谱 | DMS 音频小组件 |
| `qt6-qtmultimedia` | Qt 音频 | DMS 使用 |
| `power-profiles-daemon` | 电源模式 | 服务可用时使用 |
| `cups-pk-helper` | 打印机集成 | 需配置打印服务 |
| `i2c-tools` | DDC/CI 显示器亮度 | 需硬件支持 |

## DMS Greeter

镜像启用 greetd，配置文件为 `/etc/greetd/config.toml`。检查：

```bash
systemctl status greetd
dms-greeter status
dms-greeter sync
```

## Fcitx5 / Rime

Fcitx5 软件包已预装，但用户级 autostart、会话环境变量和雾凇拼音配置需运行 `just fcitx-setup`。环境变量完整生效需要重新登录图形会话。GTK 原生 Wayland 应用不强制设置 `GTK_IM_MODULE`。

## QEMU / KVM

镜像包含 QEMU/KVM、libvirt、virt-manager、virt-install、OVMF 和 swtpm。检查：

```bash
virt-host-validate
virsh -c qemu:///system list --all
```

首次使用默认 NAT 网络：

```bash
sudo virsh net-autostart default
sudo virsh net-start default
```


## Waydroid

镜像预装 `waydroid` 并启用 `waydroid-container.service`，但不会自动初始化 Android 镜像。首次使用时选择镜像类型：

```bash
sudo waydroid init -s GAPPS
```

也可以将 `GAPPS` 替换为 `VANILLA` 或 `FOSS`。初始化完成后启动容器：

```bash
sudo systemctl start waydroid-container
waydroid session start
```

Android 镜像存储在 `/var/lib/waydroid`，不会预先打包进 bootc 镜像。
