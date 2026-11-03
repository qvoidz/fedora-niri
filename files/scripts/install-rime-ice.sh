#!/usr/bin/env bash
set -euo pipefail

# Seed Rime Ice for newly created user accounts. Existing accounts are not modified.
install -d -m 0755 /etc/skel/.local/share/fcitx5/rime
git clone --depth 1 https://github.com/iDvel/rime-ice.git /tmp/rime-ice
cp -a /tmp/rime-ice/. /etc/skel/.local/share/fcitx5/rime/
cat > /etc/skel/.local/share/fcitx5/rime/default.custom.yaml <<'EOF'
patch:
  __include: rime_ice_suggestion:/
EOF
rm -rf /tmp/rime-ice
