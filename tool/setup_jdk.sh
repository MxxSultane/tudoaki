#!/usr/bin/env bash
set -euo pipefail
jdk_root=/workspace/.tools/jdk
if [[ -x "$jdk_root/bin/javac" ]]; then
  "$jdk_root/bin/javac" -version
  exit 0
fi
if [[ -e "$jdk_root" ]]; then
  echo 'An incomplete JDK directory exists; inspect before replacing.' >&2
  exit 1
fi
stage=$(mktemp -d /tmp/tudo-aki-jdk.XXXXXX)
trap 'rm -rf "$stage"' EXIT
curl -fsSL 'https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.13%2B9/OpenJDK21U-jdk_x64_linux_hotspot_21.0.13_9.tar.gz' -o "$stage/jdk.tar.gz"
# SHA-256 published by Eclipse Adoptium with the official release asset.
python3 - "$stage/jdk.tar.gz" <<'PY'
import hashlib, pathlib, sys
h = hashlib.sha256()
with pathlib.Path(sys.argv[1]).open('rb') as f:
    for block in iter(lambda: f.read(1024 * 1024), b''): h.update(block)
if h.hexdigest() != 'd7f5d5cf865a2902b70ff549b97586a7d3f234e016f041ab447ea740c7d66d1c':
    raise SystemExit('JDK checksum mismatch; refusing installation')
PY
tar -xzf "$stage/jdk.tar.gz" -C "$stage"
mkdir -p /workspace/.tools
mv "$stage/jdk-21.0.13+9" "$jdk_root"
"$jdk_root/bin/javac" -version
