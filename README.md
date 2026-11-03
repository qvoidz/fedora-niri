# Fedora Niri

基于 BlueBuild 的 Fedora Atomic 自定义镜像，使用 NVIDIA 驱动基础镜像，提供 Niri、DankMaterialShell（DMS）、DMS Greeter 和常用桌面工具。

## 镜像内容

- 桌面：Niri（Git 版）、DankMaterialShell、DMS Greeter、Kitty
- DMS 功能组件：DankSearch（文件搜索）、dgop（系统资源监控）、Cava（音频可视化）、Qt Multimedia（系统声音反馈）、电源配置、打印机管理和 DDC 显示器亮度工具
- 输入法：Fcitx5、Rime、雾凇拼音；包含用户级自动启动项和会话环境变量
- 字体：Cascadia Code Nerd Font
- DNF/RPM：Microsoft Edge、Clash Verge Rev（来自官方源/Release，Clash Verge Rev 构建时校验 SHA-256）
- Flathub：微信、腾讯会议、Visual Studio Code、Steam、Lutris

## 安装

```bash
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/qvoidz/fedora-niri:latest
systemctl reboot
```

首次重启后切换到已签名镜像：

```bash
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/qvoidz/fedora-niri:latest
systemctl reboot
```

## 首次登录配置

镜像会启用 greetd，并将 DMS Greeter 的登录会话固定为 Niri。DMS Greeter 会替代原有显示管理器。

首次进入自己的 Niri 桌面后，以普通用户执行：

```bash
dms setup
```

该命令生成 Niri 的 DMS 配置，并将 DMS 服务绑定到 Niri 会话。不要再额外添加 `dms run`，避免重复启动。

### 文件搜索

DankSearch 已安装，DMS 启动器中输入 `/` 可调用文件搜索。首次登录后启用用户索引服务：

```bash
systemctl --user enable --now dsearch
dsearch index generate
```

### Greeter 主题同步

Greeter 已配置为使用 Niri。首次登录桌面后，可运行：

```bash
dms-greeter sync
dms-greeter status
```

同步命令会配置 Greeter 读取当前用户的 DMS 主题、壁纸和设置。多用户环境下，主用户执行一次完整同步；其他用户按上游说明执行 `dms-greeter sync --profile`。

### Fcitx5 / Rime

Fcitx5 会随图形会话自动启动。镜像已提供用户级 autostart 文件，以及 systemd 用户环境变量。GTK 原生 Wayland 应用保留 Wayland text-input-v3，不强制设置 `GTK_IM_MODULE`；Qt、XWayland 和 SDL 使用相应的 Fcitx 兼容变量。

首次登录后打开 Fcitx5 配置工具，将 Rime 添加为输入法；雾凇拼音数据已预置到新用户的 Rime 目录。

## 签名验证

```bash
cosign verify --key cosign.pub ghcr.io/qvoidz/fedora-niri
```

GitHub 仓库需要配置 Actions Secret `SIGNING_SECRET`（与仓库中的 `cosign.pub` 配对的 Cosign 私钥），否则 BlueBuild 的签名阶段会失败。

## 构建与更新

GitHub Actions 会在 Pull Request、推送到仓库和定时任务时构建镜像。Clash Verge Rev 的更新工作流每天检查官方最新稳定版；发现新版本后更新版本号和 SHA-256，并显式触发镜像构建。
