# 安装后说明

## 自动初始化

镜像通过 systemd 用户服务 \`fedora-niri-init.service\` 在用户会话启动时运行 \`/usr/libexec/fedora-niri/init\`。

- 首次运行先执行一次 \`cleanup -y\`。该操作会清理 HOME 中大部分个人数据，包括 SSH/GPG 密钥；请在首次登录前备份。恢复状态目录 \`~/.local/state/fedora-niri\` 会保留。
- 首次清理完成标记与系统初始化标记分开保存。后续步骤失败不会重复执行完整清理。
- 通过 booted OSTree deployment checksum 判断系统升级，不依赖镜像 tag。
- 新部署先备份受管理的 Niri、Quickshell、DMS、Kitty、Neovim 配置，再刷新配置。
- 按 DMS、Niri、Kitty、Neovim、Fcitx5 顺序执行。
- 全部步骤成功后才写入部署标记；失败时下次登录重试。

备份位置：\`~/.local/state/fedora-niri/upgrade-backups/<deployment-checksum>/\`。

## Just 命令

使用普通 \`just\`，无需 ujust 或 blujust：

| 命令 | 说明 |
|---|---|
| \`just init\` | 执行主初始化流程 |
| \`just niri-setup\` | 部署 Niri / Quickshell 配置及设备默认值 |
| \`just dms-setup\` | 配置 DMS Greeter、DMS 默认设置和中文 locale |
| \`just kitty-setup\` | 管理 Kitty 配置 |
| \`just nvim-setup\` | 部署 LazyVim Starter |
| \`just fcitx-setup\` | 手动配置 Fcitx5、Rime 和雾凇拼音 |
| \`just cleanup\` | 交互式清理 |

XDG user-dirs 脚本及 Just 任务已移除。

## 配置模块行为

每个配置模块使用 \`config-setup\` 保存原始配置、记录安装状态，并在失败时回滚。自动升级使用 refresh 事务快照，避免覆盖最初安装时的卸载恢复备份。Kitty 仅管理指定字段，不替换整个 \`kitty.conf\`。

## DMS Greeter 与中文环境

镜像提供 `/etc/greetd/config.toml`，默认会以 `greeter` 系统用户运行 `/usr/bin/dms-greeter --command niri`。`greetd.service` 已在镜像构建时启用，因此开机进入 Dux Greeter 登录界面。DMS 初始化仍会运行 `dms-greeter install --yes` 完成账户、权限、PAM 和 Greeter 配置，并在命令前设置 `LANG=zh_CN.UTF-8`。

DMS setup 以普通用户身份执行 \`dms-greeter install --yes\`，再在 greetd \`[default_session].command\` 的启动边界设置 \`LANG=zh_CN.UTF-8\`。原始 greetd 配置保存在 DMS 模块状态目录，卸载时恢复。

检查：

\`\`\`bash
systemctl status greetd
dms-greeter status
dms-greeter sync
\`\`\`

## sudo

镜像在 \`/etc/sudoers.d/99-wheel-nopasswd\` 中为 wheel 组启用免密码 sudo；构建时将文件权限设置为 0440，并通过 \`visudo -cf /etc/sudoers\` 验证。

## Fcitx5 / Rime

Fcitx5 软件包预装，但用户级配置不属于自动初始化。手动运行 \`just fcitx-setup\`。已有雾凇拼音仓库以 fast-forward 方式更新；不存在时克隆。环境变量完整生效需要重新登录图形会话。

## Waydroid

\`\`\`bash
sudo waydroid init -s GAPPS
sudo systemctl start waydroid-container
waydroid session start
\`\`\`

可将 \`GAPPS\` 替换为 \`VANILLA\` 或 \`FOSS\`。

## QEMU / KVM

\`\`\`bash
virt-host-validate
virsh -c qemu:///system list --all
sudo virsh net-autostart default
sudo virsh net-start default
\`\`\`
