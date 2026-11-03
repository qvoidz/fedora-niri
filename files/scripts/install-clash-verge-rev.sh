#!/usr/bin/env bash
set -euo pipefail

version="2.5.10"
rpm_name="Clash.Verge-${version}-1.x86_64.rpm"
rpm_url="https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v${version}/${rpm_name}"
rpm_path="/tmp/${rpm_name}"
expected_sha256="8ae1e802da51fd56e3dcaec694fa17bc6d2c5aeaf13521f4492c0ec5a1d109aa"

curl --fail --location --retry 3 --output "${rpm_path}" "${rpm_url}"
echo "${expected_sha256}  ${rpm_path}" | sha256sum --check --status

dnf install --assumeyes "${rpm_path}"
rm -f "${rpm_path}"
