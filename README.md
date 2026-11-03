# Fedora Niri

基于 BlueBuild 的 Fedora Atomic 自定义镜像，使用 NVIDIA 驱动基础镜像，提供 Niri、DankMaterialShell（DMS）、DMS Greeter 和开箱即用的桌面配置。

## 镜像内容

- 桌面：Niri（Git 版）、DankMaterialShell、DMS Greeter、greetd、Kitty、Fish
- 编辑器：Neovim + LazyVim 官方 Starter（首次用户登录时自动初始化）
- Neovim 工具：Git、curl、ripgrep、fd、tree-sitter-cli、GCC、Make、unzip、Python Neovim 支持
- DMS 功能组件：DankSearch（文件搜索）、dgop（系统资源监控）、Cava（音频可视化）、Qt Multimedia（系统声音反馈）、电源配置、打印机管理和 DDC 显示器亮度工具
- 字体：系统全局默认使用 Noto Sans、Noto Serif、Noto Sans Mono，并配置 Noto CJK SC 与 Noto Color Emoji 回退；额外安装 Cascadia Code Nerd Font 供 Kitty 使用
- DNF/RPM：Microsoft Edge、Microsoft 官方仓库的 Visual Studio Code、Clash Verge Rev（来自官方 Release，构建时校验 SHA-256）
- 输入法：Fcitx5、Rime、雾凇拼音；包含用户级自动启动项和会话环境变量
- 虚拟化：QEMU/KVM、libvirt、virt-manager、virt-install、UEFI 固件（OVMF）和 TPM 模拟器；系统启用 Fedora 模块化 virtqemud 服务和 virtnetworkd socket
- Flathub：微信、腾讯会议、Linux QQ、Steam、Lutris

## 自动配置

目标是切换镜像并重启后即可使用，不需要再手动执行初始化命令。

字体默认值在构建镜像时通过系统级 Fontconfig 配置写入，所有遵循 Fontconfig 的应用都会优先使用 Noto 字体；Kitty 因为单独指定了 Nerd Font，仍使用 Cascadia Code Nerd Font 以保证终端图标正常显示。

首次用户登录时，系统级镜像预置的 systemd 用户服务会自动：
- 执行 `dms setup headless --compositor niri --terminal kitty --skip-existing`，完成 DMS 初始化并绑定 DMS systemd 服务。
- 对新建的 Kitty 配置仅追加三项设置：字体 `CaskaydiaCove Nerd Font`、Shell `/usr/bin/fish`、透明度 `0.8`；不修改其他 Kitty 配置。
- 在用户没有 Neovim 配置时，克隆 LazyVim 官方 Starter 到 `~/.config/nvim`。

已有的 `~/.config/kitty/kitty.conf`、`~/.config/nvim` 以及已有的 DMS 配置不会被覆盖；已有 Kitty 配置也不会被自动修改。DMS 初始化使用无交互模式并跳过已有配置。LazyVim 插件在第一次运行 `nvim` 时下载，因此首次启动 Neovim 需要网络连接。

## 安装

从 Fedora Silverblue 等 Fedora Atomic 系统切换到本镜像，只需执行以下命令并重启：

```bash
sudo bootc switch ghcr.io/qvoidz/fedora-niri:latest
sudo systemctl reboot
```

## 可选功能配置

以下配置不影响 Niri 桌面基本使用，仅在需要对应功能时执行。

### 文件搜索

DankSearch 已安装。需要启用用户索引服务时：

```bash
systemctl --user enable --now dsearch
dsearch index generate
```

### Greeter 主题同步

需要同步登录界面主题时：

```bash
dms-greeter sync
dms-greeter status
```

### Fcitx5 / Rime

Fcitx5 会随图形会话自动启动。镜像提供用户级 autostart 文件，以及 systemd 用户环境变量。GTK 原生 Wayland 应用保留 Wayland text-input-v3，不强制设置 `GTK_IM_MODULE`；Qt、XWayland 和 SDL 使用相应的 Fcitx 兼容变量。

首次使用 Rime 时，打开 Fcitx5 配置工具，将 Rime 添加为输入法；雾凇拼音数据已预置到新用户的 Rime 目录。

## 签名验证

本仓库包含 Cosign 签名配置。需要手动验证镜像签名时，可使用仓库中的 `cosign.pub`：

```bash
cosign verify --key cosign.pub ghcr.io/qvoidz/fedora-niri
```

GitHub 仓库需要配置 Actions Secret `SIGNING_SECRET`（与 `cosign.pub` 配对的 Cosign 私钥），否则 BlueBuild 的签名阶段会失败。签名验证说明不属于首次切换步骤。

## 构建与更新

GitHub Actions 会在 Pull Request、推送到仓库和定时任务时构建镜像。Clash Verge Rev 的更新工作流每天检查官方最新稳定版；发现新版本后更新版本号和 SHA-256，并显式触发镜像构建。

## QEMU / KVM 虚拟化

镜像预装 QEMU/KVM、libvirt、Virtual Machine Manager（virt-manager）、virt-install、OVMF UEFI 固件、swtpm 和默认 NAT 网络所需组件。系统启用 Fedora 的模块化 `virtqemud.service` 和 `virtnetworkd.socket`：QEMU 虚拟机管理守护进程随系统启动，虚拟网络守护进程按需启动。

首次使用前确认固件中已开启 Intel VT-x 或 AMD-V。启动 virt-manager 后连接系统级 QEMU/KVM（`qemu:///system`）。检查虚拟化状态：

```bash
virt-host-validate
virsh -c qemu:///system list --all
```

如需使用 libvirt 默认 NAT 网络，首次启用：

```bash
sudo virsh net-autostart default
sudo virsh net-start default
```

## QQ 与 Visual Studio Code

- Linux QQ 通过 Flathub 的 `com.qq.QQ` 安装。Flathub 页面标注该包由 Tencent 开发，但尚未通过 Tencent 验证；它是社区提供的 Flatpak 包。
- Visual Studio Code 使用 Microsoft 官方 RPM 仓库安装，随 DNF 更新。
