# Fedora Niri

基于 BlueBuild 的 Fedora Atomic / bootc 自定义镜像，提供 Niri、DMS、Dux Greeter 和用户级配置初始化。

## 镜像内容

- **桌面与登录**：Niri、DMS、Dux Greeter、greetd、Kitty。
- **Dux 组件**：Dux Shell、Dux GOP、Dux Search、Dux Calendar、Dux Files，以及 Quickshell、Matugen、Cliphist、Cava 等依赖。
- **Shell 与工具**：Fish、Just、NetworkManager、Neovim、Git、curl、ripgrep、fd、GCC、Make。
- **字体**：Google Noto 字体、JetBrainsMono Nerd Font。
- **输入法**：Fcitx5、Rime 及雾凇拼音所需组件（用户级配置手动运行）。
- **应用**：Microsoft Edge、Visual Studio Code、Clash Verge Rev，以及 Flathub 的微信、腾讯会议、QQ、Steam、Lutris。
- **其他**：Waydroid、QEMU/KVM、libvirt。

## 安装

\`\`\`bash
sudo bootc switch ghcr.io/qvoidz/fedora-niri:latest
sudo systemctl reboot
\`\`\`

## 自动初始化

首次登录时，systemd 用户服务运行 \`/usr/libexec/fedora-niri/init\`：

1. 首次初始化执行一次 \`cleanup -y\`。它会清理 HOME 中的大部分个人数据，包括 SSH/GPG 密钥；执行前请备份。恢复状态目录 \`~/.local/state/fedora-niri\` 会保留。
2. 按顺序部署 Niri、DMS、Kitty、Neovim 配置。
3. 使用当前 booted OSTree deployment checksum 判断系统是否升级，不依赖可变的镜像标签。
4. 新部署会先备份受管理的用户配置，再刷新配置；升级不会再次执行完整清理。
5. 全部步骤成功后才更新部署标记。失败会保留旧标记，下次登录自动重试。

升级备份位于 \`~/.local/state/fedora-niri/upgrade-backups/<deployment-checksum>/\`。自动初始化不运行 Fcitx5，也不执行 XDG user-dirs 修改。

## 手动命令

运行 \`just\` 查看任务：

| 命令 | 用途 |
|---|---|
| \`just init\` | 手动运行主初始化流程 |
| \`just niri-setup\` | 部署 Niri / Quickshell 配置和设备默认值 |
| \`just dms-setup\` | 初始化 DMS Greeter、DMS 默认设置及中文 locale |
| \`just kitty-setup\` | 设置 Kitty 字体、Fish shell 和透明度 |
| \`just nvim-setup\` | 部署 LazyVim Starter |
| \`just fcitx-setup\` | 手动配置 Fcitx5、Rime 和雾凇拼音 |
| \`just cleanup\` | 交互式清理用户配置和数据 |

配置模块支持 Install / Uninstall / Cancel；卸载会恢复模块安装前备份。自动初始化会对已安装模块执行 refresh，模块失败时会尝试恢复并在下次登录重试。

## 其他功能

DankSearch 首次使用前生成索引：

\`\`\`bash
dsearch index generate
\`\`\`

Waydroid：

\`\`\`bash
sudo waydroid init -s GAPPS
\`\`\`

也可选择 \`VANILLA\` 或 \`FOSS\`。

QEMU / KVM：

\`\`\`bash
virt-host-validate
virsh -c qemu:///system list --all
sudo virsh net-autostart default
sudo virsh net-start default
\`\`\`

## 应用来源与签名

微信、腾讯会议、QQ、Steam、Lutris 使用系统级 Flathub。Edge 和 VS Code 使用 Microsoft DNF 仓库。Clash Verge Rev 从官方 Release 下载并校验 SHA-256。

\`\`\`bash
cosign verify --key cosign.pub ghcr.io/qvoidz/fedora-niri
\`\`\`
