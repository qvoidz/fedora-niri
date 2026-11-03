# 安装后说明

## 普通 Just 命令

镜像使用普通 `just` 和全局 Justfile，不依赖 `ujust` 或 `blujust`。运行 `just` 查看任务列表。

| 命令 | 说明 |
| --- | --- |
| `just dms-setup` | Install/Uninstall/Cancel；安装时调用 `duxinstall -c niri -t kitty -y` |
| `just kitty-setup` | 管理 Kitty 配置 |
| `just fcitx-setup` | 管理 Fcitx5、Rime 和雾凇拼音用户配置 |
| `just fonts-setup` | 选择 Kitty 字体 |
| `just nvim-setup` | 管理 LazyVim Starter |
| `just user-dirs` | 固定英文 XDG 用户目录 |
| `just cleanup` | 按类别清理当前用户数据 |

配置安装会先备份模块管理的目标；卸载时删除目标当前内容并恢复备份。DMS 在启动 duxinstall 前备份 Niri、Quickshell 和 DMS 配置目录。请注意，卸载会恢复这些目录的安装前快照，安装后在这些目录里新增的个人修改也会被覆盖。

## cleanup 安全说明

`just cleanup` 会要求输入 `RESET`，随后删除当前用户 HOME 下的所有文件和目录，包括个人文件、隐藏配置、应用数据、缓存、密钥及模块备份。它不会触碰系统镜像、系统软件包、系统服务或其他用户。不可撤销，执行前务必备份。

## 英文 XDG 用户目录

运行 `just user-dirs` 后，文档、下载、图片、音乐、视频、桌面、模板和公共目录将使用英文名称。命令更新 `~/.config/user-dirs.dirs`，并禁用按 locale 自动翻译目录名。若旧中文目录与目标英文目录同时存在，脚本会保留两者并提示，不会擅自合并。

## DMS 检查

```bash
dms --help
dms version
systemctl --user status dms
journalctl --user -u dms -b
```

DMS 配置通过 `duxinstall -c niri -t kitty -y` 安装；这里不使用在当前不可变系统上会失败的 `dms setup`。

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
