# 安装后说明

## DMS Greeter

镜像包含 `dms-greeter`，但不会自动启用。请根据当前安装版本的文档配置 `/etc/greetd/config.toml`，确认命令行参数后再启用 `greetd.service`。启用 greetd 会替换当前显示管理器，因此需要手动执行。

## 雾凇拼音

镜像会将雾凇拼音预置到 `/etc/skel/.local/share/fcitx5/rime`，新建用户会自动获得配置。不会覆盖已有用户的数据；已有用户可参考上游安装说明：
https://github.com/iDvel/rime-ice/blob/main/others/docs/Installation.md

## 应用来源

- 微信、腾讯会议、Visual Studio Code、Steam、Lutris：系统级 Flathub 应用。
- Microsoft Edge：通过微软 DNF 仓库安装 RPM。
- Clash Verge Rev：从官方 GitHub Release 下载 RPM，安装前校验 SHA-256。自动更新工作流每天检查稳定版，并在版本变化时更新镜像安装脚本。
