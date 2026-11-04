# Fedora Niri

基于 BlueBuild 的 Fedora Atomic / bootc 自定义镜像，使用 NVIDIA 驱动基础镜像，提供 Niri、Dux Shell（DMS）、Dux Greeter 和可手动管理的用户配置。

## 镜像内容

- **桌面与登录**：Niri（`yalter/niri-git`）、DMS、Dux Greeter、greetd、Kitty。
- **Dux 组件**：Dux Shell、Dux GOP、Dux Search、Dux Calendar，以及 Quickshell、Matugen、Cliphist、Cava 等依赖；不安装 Dux Files。
- **文件管理**：GNOME Files（Nautilus），右键菜单支持使用 Kitty 打开终端。
- **Shell 与系统工具**：Fish、Just、XDG 用户目录工具、NetworkManager。
- **字体**：CascadiaCode Nerd Font、JetBrainsMono Nerd Font、Google Noto Sans/Serif/Mono/CJK/Emoji。
- **输入法**：Fcitx5、Rime 及雾凇拼音所需组件。用户级配置由 Just 手动部署。
- **开发工具**：Neovim、Git、curl、ripgrep、fd、tree-sitter-cli、GCC、Make、unzip、Python Neovim 支持。
- **应用**：Microsoft Edge、Visual Studio Code、Clash Verge Rev、微信、腾讯会议、Linux QQ、Steam、Lutris。
- **Android**：Waydroid（只预装容器，不自动初始化 Android 镜像）。
- **虚拟化**：QEMU/KVM、libvirt、virt-manager、virt-install、OVMF 和 swtpm。

## 安装

从 Fedora Silverblue、Kinoite 或其他兼容的 Fedora bootc/Atomic 系统切换：

```bash
sudo bootc switch ghcr.io/qvoidz/fedora-niri:latest
sudo systemctl reboot
```

## 用户配置（普通 just）

镜像提供全局 Justfile，使用普通 `just`，不需要 `ujust` 或 `blujust`。功能脚本集中在 `/usr/libexec/fedora-niri/`，全局 Justfile 位于 `/usr/share/fedora-niri/Justfile`。运行：

```bash
just
```

查看可用任务。`dms-setup`、`kitty-setup`、`fcitx-setup`、`fonts-setup` 和 `nvim-setup` 提供 **Install / Uninstall / Cancel** 菜单；`cleanup` 与 `user-dirs` 是独立操作：

| 命令 | 用途 |
| --- | --- |
| `just dms-setup` | 部署 DMS/Niri/Kitty 配置、启用 Dux 全部可选组件（排除 Dux Files），并配置 Nautilus 的 Kitty 右键终端 |
| `just kitty-setup` | 管理 Kitty 配置（Fish shell、透明度） |
| `just fcitx-setup` | 部署 Fcitx5 自动启动、会话环境变量和雾凇拼音 |
| `just fonts-setup` | 从已安装字体中选择 DMS 默认界面字体 |
| `just nvim-setup` | 安装 LazyVim 官方 Starter |
| `just user-dirs` | 将 XDG 文档、下载、图片等标准目录固定为英文名称 |
| `just cleanup` | 按类别清理当前用户配置、缓存、应用数据、个人文件和用户级 Flatpak |

配置任务会在安装前备份它们管理的目标路径，卸载时删除这些目标的当前版本并恢复备份。DMS 在运行 duxinstall 前备份 Niri、Quickshell、Kitty 和 DMS 的相关用户配置根目录。卸载恢复会将这些目录还原到安装前状态，因此安装后在这些目录里新增的个人修改也会被覆盖；需要保留时请先另行备份。

### cleanup 注意事项

`just cleanup` 会逐项询问要删除的用户配置、缓存、应用数据、XDG 目录、个人文件和用户级 Flatpak；每项提示为 `[Y/n]`，直接回车默认为**确认删除**，输入 `n` 保留该项。

`just cleanup -- -y` 会跳过所有问题，直接执行全部清理。该操作可能删除 HOME 中几乎所有个人数据和密钥，且不可撤销；执行前务必备份。系统级 Flatpak、RPM、系统镜像和其他用户的数据不受影响。

### 英文用户目录

`just user-dirs` 使用 XDG User Directories 标准更新 `~/.config/user-dirs.dirs`，并禁用自动本地化重写，避免中文桌面 locale 再次生成中文目录。若中英文目录同时存在，不会自动合并或删除旧目录。

## 可选功能

### DankSearch

Dux Search 已预装；`just dms-setup` 会自动启用用户级服务，首次使用前生成索引：

```bash
dsearch index generate
```

### DMS Greeter

```bash
dms-greeter sync
dms-greeter status
```

### Waydroid

Waydroid 容器服务已加入镜像并启用，但不会自动下载 Android 镜像。首次使用时自行选择镜像类型：

```bash
sudo waydroid init -s GAPPS
```

不需要 Google 服务时，可选择 `VANILLA` 或 `FOSS`。初始化会下载镜像并写入 `/var/lib/waydroid`。

### QEMU / KVM

首次使用前在固件中开启 Intel VT-x 或 AMD-V：

```bash
virt-host-validate
virsh -c qemu:///system list --all
sudo virsh net-autostart default
sudo virsh net-start default
```

## 应用来源与更新

- 微信、腾讯会议、Linux QQ、Steam、Lutris：系统级 Flathub 应用。
- Microsoft Edge、Visual Studio Code：各自使用 Microsoft 官方 DNF 仓库。
- Clash Verge Rev：从官方 GitHub Release 下载 RPM，安装前校验 SHA-256。
- Dux、Niri、Nautilus 终端扩展：通过各自 COPR 仓库安装。
- GitHub Actions 在 Pull Request、推送和每日定时任务时构建镜像；Clash Verge Rev 安装脚本在构建时获取最新稳定版，并校验 Release 提供的 SHA-256。

## 签名验证

```bash
cosign verify --key cosign.pub ghcr.io/qvoidz/fedora-niri
```

GitHub Actions 需要配置与 `cosign.pub` 配对的 `SIGNING_SECRET`。
