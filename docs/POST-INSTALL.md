# 安装后说明

## 自动用户配置

首次登录时，系统级 systemd 用户服务 `fedora-niri-first-login.service` 会自动初始化默认用户配置：

- 如果 `~/.config/nvim` 不存在，克隆 LazyVim 官方 Starter。
- 如果 `~/.config/kitty/kitty.conf` 不存在，复制默认 Kitty 配置。
- Kitty 默认使用 Cascadia Code Nerd Font 和 Fish。
- 已存在的 Neovim/Kitty 配置不会被覆盖。

检查初始化服务：

```bash
systemctl --user status fedora-niri-first-login.service
journalctl --user -u fedora-niri-first-login.service -b
```

LazyVim 插件在第一次启动 `nvim` 时安装，需连接网络。Neovim 版本应满足 LazyVim 的最低要求（0.11.2）；Fedora 43 当前仓库提供的版本高于该要求。

## 字体

- `Cascadia Code Nerd Font`：用于 Kitty、Neovim 图标和终端提示符。
- `google-noto-fonts-all`：Fedora 全局安装的 Google Noto 全字体家族，覆盖大量语言和文字系统。

## DMS 与 Niri

首次登录自己的 Niri 桌面后，以普通用户运行：

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

镜像包含 `greetd` 和 `dms-greeter`，并已写入 `/etc/greetd/config.toml`：

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

首次登录桌面后运行 `dms-greeter sync`，同步当前用户的 DMS 主题、壁纸和设置到登录界面。

## Fcitx5 / Rime

- `fcitx5-autostart` 提供系统级 XDG 自动启动项和 Fedora 环境配置。
- `/etc/skel/.config/autostart/org.fcitx.Fcitx5.desktop` 为新用户提供用户级启动项。
- `/etc/environment.d/90-fcitx5.conf` 和用户 skeleton 中的同名配置提供环境变量。
- 不设置全局 `GTK_IM_MODULE`，以免覆盖 GTK 原生 Wayland text-input-v3；Qt、XWayland 和 SDL 使用 Fcitx 对应变量。

首次登录后打开 `fcitx5-configtool`，将 Rime 添加到输入法列表。雾凇拼音数据已预置到新用户的 Rime 目录。

## 应用来源

- 微信、腾讯会议、Visual Studio Code、Steam、Lutris：系统级 Flathub 应用。
- Microsoft Edge：通过微软 DNF 仓库安装 RPM。
- Clash Verge Rev：从官方 GitHub Release 下载 RPM，安装前校验 SHA-256。自动更新工作流每天检查稳定版，并在版本变化时更新镜像安装脚本。
