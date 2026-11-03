# Fedora Niri

基于 BlueBuild 的 Fedora Atomic 自定义镜像，使用 NVIDIA 驱动基础镜像，提供 Niri Git 版桌面、DankMaterialShell 和常用应用。

## 镜像内容

- 桌面：Niri（Git 版）、DankMaterialShell、DMS Greeter、Kitty
- 输入法：Fcitx5、Rime、雾凇拼音
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

## 签名验证

```bash
cosign verify --key cosign.pub ghcr.io/qvoidz/fedora-niri
```

## 安装后配置

首次启动后的 Greeter 配置、greetd 启用方式和 Rime Ice 说明见 [安装后说明](docs/POST-INSTALL.md)。

## 构建与更新

GitHub Actions 会在 Pull Request、推送到仓库和定时任务时构建镜像。Clash Verge Rev 的更新工作流每天检查官方最新稳定版；发现新版本后更新版本号和 SHA-256，并显式触发镜像构建。
