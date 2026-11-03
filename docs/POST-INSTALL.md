# 安装后说明

## DMS 与 Niri

镜像预装 DMS 和它的可选组件。首次登录自己的 Niri 桌面后，以普通用户运行：

```bash
dms setup
```

这会生成 Niri 的 DMS 配置，并将 DMS systemd 用户服务绑定到 Niri 会话。不要再手动添加 `dms run`，否则可能启动两个实例。

常用检查：

```bash
dms --help
dms version
systemctl --user status dms
journalctl --user -u dms -b
```

## DMS 可选功能

| 组件 | 用途 | 启用方式 |
| --- | --- | --- |
| `danksearch`（命令 `dsearch`） | 文件名/内容搜索，DMS 启动器输入 `/` | `systemctl --user enable --now dsearch`，首次运行 `dsearch index generate` |
| `dgop` | CPU、内存、GPU、温度等系统资源数据 | DMS 小组件直接读取 |
| `cava` | 音频频谱可视化 | DMS 音频可视化小组件 |
| `qt6-qtmultimedia` | Qt 音频播放/系统声音反馈 | DMS 使用 |
| `power-profiles-daemon` | 电源模式切换 | 需要服务可用 |
| `cups-pk-helper` | 打印机管理集成 | 需系统打印服务及打印机配置 |
| `i2c-tools` | DDC/CI 外接显示器亮度控制 | 需显示器和硬件支持 |

可选组件安装不代表每项硬件功能都必然可用；例如 DDC 亮度需要显示器支持，打印功能需要配置打印服务。

## DMS Greeter

镜像包含 `greetd` 和 `dms-greeter`，并已写入：

`/etc/greetd/config.toml`

默认会话命令：

```toml
[terminal]
vt = 1

[default_session]
user = "greeter"
command = "/usr/bin/dms-greeter --command niri"
```

镜像已启用 `greetd.service`，因此它会作为登录管理器启动，并替代原有显示管理器。检查状态：

```bash
systemctl status greetd
dms-greeter status
```

首次登录桌面后运行 `dms-greeter sync`，同步当前用户的 DMS 主题、壁纸和设置到登录界面。多用户系统请按上游说明配置 greeter 组及 `sync --profile`。

## Fcitx5 / Rime

- `fcitx5-autostart` 提供系统级 XDG 自动启动项和 Fedora 环境配置。
- `/etc/skel/.config/autostart/org.fcitx.Fcitx5.desktop` 为新用户提供用户级启动项。
- `/etc/environment.d/90-fcitx5.conf` 和用户 skeleton 中的同名配置提供环境变量。
- 不设置全局 `GTK_IM_MODULE`，以免覆盖 GTK 原生 Wayland text-input-v3；Qt、XWayland 和 SDL 使用 Fcitx 对应变量。

首次登录后打开 `fcitx5-configtool`，将 Rime 添加到输入法列表。雾凇拼音数据已预置到 `/etc/skel/.local/share/fcitx5/rime`，新用户首次创建时会获得配置。

## 字体

已安装 Cascadia Code Nerd Font，终端字体名称可在字体选择器中查找 Cascadia Code NF。

## 应用来源

- 微信、腾讯会议、Visual Studio Code、Steam、Lutris：系统级 Flathub 应用。
- Microsoft Edge：通过微软 DNF 仓库安装 RPM。
- Clash Verge Rev：从官方 GitHub Release 下载 RPM，安装前校验 SHA-256。自动更新工作流每天检查稳定版，并在版本变化时更新镜像安装脚本。
