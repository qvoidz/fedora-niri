# Fedora Niri

基于 BlueBuild 的 Fedora Atomic / bootc 自定义镜像，使用 NVIDIA 驱动基础镜像，提供 Niri、DankMaterialShell（DMS）、DMS Greeter 和可手动管理的用户配置。

## 镜像内容

- 桌面与登录：Niri（COPR Git 版）、DankMaterialShell、DMS Greeter、greetd、Kitty、Fish。
- 配置管理：普通 `just`，提供 DMS、Kitty、Fcitx5/Rime、字体和 Neovim/LazyVim 配置任务。
- 编辑器工具：Neovim、Git、curl、ripgrep、fd、tree-sitter-cli、GCC、Make、unzip、Python Neovim 支持。
- 字体：CascadiaCode Nerd Font、JetBrainsMono Nerd Font、Google Noto 字体；系统 Fontconfig 优先使用 Noto。
- 输入法软件：Fcitx5、Rime 及雾凇拼音所需组件。用户级配置由 Just 手动部署。
- 应用：Microsoft Edge、Visual Studio Code、Clash Verge Rev、微信、腾讯会议、Linux QQ、Steam、Lutris。
- 虚拟化：QEMU/KVM、libvirt、virt-manager、virt-install、OVMF 和 swtpm。

## 安装

从 Fedora Silverblue、Kinoite 或其他兼容的 Fedora bootc/Atomic 系统切换：

```bash
sudo bootc switch ghcr.io/qvoidz/fedora-niri:latest
sudo systemctl reboot
```

## 用户配置（普通 just）

镜像提供全局 Justfile，使用普通 `just`，不需要 `ujust` 或 `blujust`。登录会话加载全局 Justfile 后，运行：

```bash
just
```

查看可用任务。配置任务均提供 **Install / Uninstall / Cancel** 菜单：

| 命令 | 用途 |
| --- | --- |
| `just dms-setup` | 运行 `duxinstall -c niri -t kitty -y` 配置 DMS/Niri |
| `just kitty-setup` | 部署 Kitty 配置（Fish shell、透明度及字体配置片段） |
| `just fcitx-setup` | 部署 Fcitx5 自动启动、会话环境变量和雾凇拼音 |
| `just fonts-setup` | 从已安装字体中选择 Kitty 使用的字体 |
| `just nvim-setup` | 安装 LazyVim 官方 Starter |
| `just user-dirs` | 将 XDG 文档、下载、图片等标准目录固定为英文名称 |
| `just cleanup` | 按类别清理当前用户配置、缓存、应用数据、个人文件和用户级 Flatpak |

配置任务会在安装前备份它们管理的目标路径，卸载时删除这些目标的当前版本并恢复备份。DMS 在运行 duxinstall 前备份 Niri、Quickshell、DMS 的相关用户配置根目录。卸载恢复会将这些目录还原到安装前状态，因此安装后在这些目录里新增的个人修改也会被覆盖；需要保留时请先另行备份。

### cleanup 注意事项

`just cleanup` 是**破坏性操作**：必须输入 `RESET` 确认，并会删除当前用户 HOME 中的全部内容，包括文档、下载、图片、隐藏配置、浏览器数据、SSH/GPG 密钥和各配置模块的备份。它不会删除系统镜像、RPM/Flatpak 软件包、系统服务或其他用户的数据。执行前请自行备份；执行后建议注销并重新登录。

### 英文用户目录

`just user-dirs` 使用 XDG User Directories 标准更新 `~/.config/user-dirs.dirs`，并禁用自动本地化重写，避免中文桌面 locale 再次生成中文目录。若中英文目录同时存在，不会自动合并或删除旧目录。

## 可选功能

### DankSearch

```bash
systemctl --user enable --now dsearch
dsearch index generate
```

### DMS Greeter

```bash
dms-greeter sync
dms-greeter status
```

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
- Visual Studio Code：Microsoft 官方 RPM 仓库。
- Microsoft Edge：Microsoft DNF 仓库。
- Clash Verge Rev：从官方 GitHub Release 下载 RPM，安装前校验 SHA-256。
- GitHub Actions 在 Pull Request、推送和定时任务时构建镜像；Clash Verge Rev 更新工作流每天检查官方稳定版。

## 签名验证

```bash
cosign verify --key cosign.pub ghcr.io/qvoidz/fedora-niri
```

GitHub Actions 需要配置与 `cosign.pub` 配对的 `SIGNING_SECRET`。
