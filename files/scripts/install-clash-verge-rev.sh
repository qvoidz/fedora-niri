#!/usr/bin/env bash
set -euo pipefail

repo="clash-verge-rev/clash-verge-rev"
api_url="https://api.github.com/repos/${repo}/releases/latest"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

release_json="${tmp_dir}/release.json"
curl --fail --location --retry 3 \
  --header "Accept: application/vnd.github+json" \
  --output "${release_json}" "${api_url}"

mapfile -t asset_info < <(python3 - "${release_json}" <<'PY'
import json
import re
import sys

with open(sys.argv[1], encoding="utf-8") as stream:
    release = json.load(stream)

assets = [
    asset for asset in release.get("assets", [])
    if re.fullmatch(r"Clash[ .]Verge-.*-1\.x86_64\.rpm", asset.get("name", ""))
    and asset.get("state") == "uploaded"
]
if len(assets) != 1:
    raise SystemExit("Expected exactly one uploaded x86_64 RPM asset")

asset = assets[0]
digest = asset.get("digest", "")
if not re.fullmatch(r"sha256:[0-9a-f]{64}", digest):
    raise SystemExit(f"Release asset has no valid SHA-256 digest: {digest!r}")

print(asset["name"])
print(asset["browser_download_url"])
print(digest.removeprefix("sha256:"))
PY
)

if [[ ${#asset_info[@]} -ne 3 ]]; then
  echo "无法解析 Clash Verge Rev Release 资源。" >&2
  exit 1
fi

rpm_name="${asset_info[0]}"
rpm_url="${asset_info[1]}"
expected_sha256="${asset_info[2]}"
rpm_path="${tmp_dir}/${rpm_name}"

curl --fail --location --retry 3 --output "${rpm_path}" "${rpm_url}"
echo "${expected_sha256}  ${rpm_path}" | sha256sum --check --status

dnf install --assumeyes "${rpm_path}"
