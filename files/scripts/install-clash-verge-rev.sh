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

rpm_asset="$(jq -er '
  [
    .assets[]
    | select(.name | test("^Clash[ .]Verge-.*-1\\.x86_64\\.rpm$"))
    | select(.state == "uploaded")
  ]
  | if length == 1 then .[0] else error("Expected exactly one x86_64 RPM asset") end
' "${release_json}")"

rpm_name="$(jq -er '.name' <<<"${rpm_asset}")"
rpm_url="$(jq -er '.browser_download_url' <<<"${rpm_asset}")"
expected_sha256="$(jq -er '.digest | select(startswith("sha256:")) | sub("^sha256:"; "")' <<<"${rpm_asset}")"
rpm_path="${tmp_dir}/${rpm_name}"

curl --fail --location --retry 3 --output "${rpm_path}" "${rpm_url}"
echo "${expected_sha256}  ${rpm_path}" | sha256sum --check --status

dnf install --assumeyes "${rpm_path}"
