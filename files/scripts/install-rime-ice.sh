#!/usr/bin/env bash
set -euo pipefail

# 将雾凇拼音配置预置到新用户的默认目录，不修改已有用户的配置
install -d -m 0755 /etc/skel/.local/share/fcitx5/rime
git clone --depth 1 https://github.com/iDvel/rime-ice.git /tmp/rime-ice
cp -a /tmp/rime-ice/. /etc/skel/.local/share/fcitx5/rime/
cat > /etc/skel/.local/share/fcitx5/rime/default.custom.yaml <<'EOF'
patch:
  __include: rime_ice_suggestion:/
EOF
rm -rf /tmp/rime-ice
