# Fedora Niri

基于 BlueBuild 的 Fedora Atomic 自定义镜像，使用 NVIDIA 驱动基础镜像，提供 Niri、DankMaterialShell（DMS）、DMS Greeter 和开箱即用的桌面配置。

## 镜像内容

- 桌面：Niri（Git 版）、DankMaterialShell、DMS Greeter、greetd、Kitty、Fish
- 编辑器：Neovim + LazyVim 官方 Starter（首次用户登录时自动初始化）
- Neovim 工具：Git、curl、ripgrep、fd、tree-sitter-cli、GCC、Make、unzip、Python Neovim 支持
- DMS 功能组件：DankSearch（文件搜索）、dgop（系统资源监控）、Cava（音频可视化）、Qt Multimedia（系统声音反馈）、电源配置、打印机管理和 DDC 显示器亮度工具
- 输入法：Fcitx5、Rime、雾凇拼音；包含用户级自动启动项和会话环境变量
- 字体：Cascadia Code Nerd Font + Fedora 的 `google-noto-fonts-all`（全局安装 Noto 全字体家族）
- DNF/RPM：Microsoft Edge、Microsoft 官方仓库的 Visual Studio Code、Clash Verge Rev（来自官方 Release，构建时校验 SHA-256）
- 虚拟化：QEMU/KVM、libvirt、virt-manager、virt-install、UEFI 固件（OVMF）和 TPM 模拟器；系统启用 libvirt socket
- Flathub：微信、腾讯会议、Linux QQ、Steam、Lutris

## 自动用户配置

首次登录时，系统级 systemd 用户服务会自动：

- 在用户没有 Neovim 配置时，克隆 LazyVim 官方 Starter 到 `~/.config/nvim`。
- 在用户没有 Kitty 配置时，将默认配置复制到 `~/.config/kitty/kitty.conf`。
- Kitty 默认使用 Cascadia Code Nerd Font 和 Fish。

已有的 `~/.config/nvim` 和 `~/.config/kitty/kitty.conf` 不会被覆盖。LazyVim 插件在第一次运行 `nvim` 时下载，因此首次启动 Neovim 需要网络连接。

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

```bash
dms-greeter sync
dms-greeter status
```

### Fcitx5 / Rime

Fcitx5 会随图形会话自动启动。镜像提供用户级 autostart 文件，以及 systemd 用户环境变量。GTK 原生 Wayland 应用保留 Wayland text-input-v3，不强制设置 `GTK_IM_MODULE`；Qt、XWayland 和 SDL 使用相应的 Fcitx 兼容变量。

首次登录后打开 Fcitx5 配置工具，将 Rime 添加为输入法；雾凇拼音数据已预置到新用户的 Rime 目录。

## 签名验证

```bash
cosign verify --key cosign.pub ghcr.io/qvoidz/fedora-niri
```

GitHub 仓库需要配置 Actions Secret `SIGNING_SECRET`（与仓库中的 `cosign.pub` 配对的 Cosign 私钥），否则 BlueBuild 的签名阶段会失败。

## 构建与更新

GitHub Actions 会在 Pull Request、推送到仓库和定时任务时构建镜像。Clash Verge Rev 的更新工作流每天检查官方最新稳定版；发现新版本后更新版本号和 SHA-256，并显式触发镜像构建。

## QEMU / KVM 虚拟化

镜像预装 QEMU/KVM、libvirt、Virtual Machine Manager（virt-manager）、virt-install、OVMF UEFI 固件、swtpm 和默认 NAT 网络所需组件。系统已启用 `libvirtd.socket`，libvirt 守护进程会在客户端连接时按需启动。

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
