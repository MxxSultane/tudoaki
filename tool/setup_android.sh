#!/usr/bin/env bash
set -euo pipefail
cd /workspace/tudoaki
source tool/env.sh
sdk_cli="$ANDROID_HOME/cmdline-tools/19.0/bin/sdkmanager"
if [[ ! -x "$sdk_cli" ]]; then
  stage=$(mktemp -d /tmp/lifeos-android.XXXXXX)
  trap 'rm -rf "$stage"' EXIT
  curl -fsSL https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip -o "$stage/tools.zip"
  # Checksum published in Google's repository2-1.xml for cmdline-tools;19.0.
  python3 - "$stage" "$ANDROID_HOME" <<'PY'
import hashlib, pathlib, sys, zipfile
stage, sdk = map(pathlib.Path, sys.argv[1:])
archive = stage / 'tools.zip'
if hashlib.sha1(archive.read_bytes()).hexdigest() != '5fdcc763663eefb86a5b8879697aa6088b041e70':
    raise SystemExit('Android CLI checksum mismatch')
with zipfile.ZipFile(archive) as z:
    for item in z.infolist():
        z.extract(item, stage)
        path = stage / item.filename
        if item.external_attr >> 16: path.chmod(item.external_attr >> 16)
(sdk / 'cmdline-tools').mkdir(parents=True, exist_ok=True)
(stage / 'cmdline-tools').rename(sdk / 'cmdline-tools/19.0')
PY
fi
# sdkmanager also needs an explicit proxy; HTTPS_PROXY is not automatic in Java.
lifeos_proxy_host=$(python3 -c 'import os,urllib.parse; p=urllib.parse.urlparse(os.environ.get("HTTPS_PROXY","")); assert not(p.username or p.password), "Use platform-supported proxy authentication"; print(p.hostname or "")')
lifeos_proxy_port=$(python3 -c 'import os,urllib.parse; p=urllib.parse.urlparse(os.environ.get("HTTPS_PROXY","")); print(p.port or 8080)')
lifeos_proxy_flags=()
if [[ -n "$lifeos_proxy_host" ]]; then
  lifeos_proxy_flags=(--proxy=http --proxy_host="$lifeos_proxy_host" --proxy_port="$lifeos_proxy_port")
fi
mkdir -p "$ANDROID_HOME/cmdline-tools" "$ANDROID_USER_HOME" "$GRADLE_USER_HOME"
if [[ ! -e "$ANDROID_HOME/cmdline-tools/latest" ]]; then
  ln -s 19.0 "$ANDROID_HOME/cmdline-tools/latest"
fi
python3 -c 'print("y\n" * 10)' | "$sdk_cli" "${lifeos_proxy_flags[@]}" --sdk_root="$ANDROID_HOME" --licenses > /tmp/lifeos-android-licenses.log
"$sdk_cli" "${lifeos_proxy_flags[@]}" --sdk_root="$ANDROID_HOME" 'platform-tools' 'platforms;android-36' 'platforms;android-35' 'platforms;android-34' 'build-tools;35.0.0' 'ndk;27.0.12077973' 'cmake;3.22.1'
test -x "$ANDROID_HOME/cmake/3.22.1/bin/cmake"
test -f "$ANDROID_HOME/ndk/27.0.12077973/source.properties"
test -x "$ANDROID_HOME/platform-tools/adb"
test -f "$ANDROID_HOME/platforms/android-36/android.jar"
test -f "$ANDROID_HOME/platforms/android-35/android.jar"
test -f "$ANDROID_HOME/platforms/android-34/android.jar"
test -x "$ANDROID_HOME/build-tools/35.0.0/aapt2"
# Java does not automatically use HTTPS_PROXY. No credentials are copied.
python3 - <<'PY'
import os, pathlib, urllib.parse
p = pathlib.Path(os.environ['GRADLE_USER_HOME']) / 'gradle.properties'
existing = p.read_text() if p.exists() else ''
additions = {'org.gradle.workers.max': '2'}
proxy = urllib.parse.urlparse(os.environ.get('HTTPS_PROXY', ''))
if proxy.hostname:
    if proxy.username or proxy.password:
        raise SystemExit('Authenticated proxy requires platform-supported Java credential injection')
    for scheme in ['http', 'https']:
        additions[f'systemProp.{scheme}.proxyHost'] = proxy.hostname
        additions[f'systemProp.{scheme}.proxyPort'] = str(proxy.port or 8080)
keys = {line.split('=', 1)[0].strip() for line in existing.splitlines() if '=' in line}
lines = [f'{key}={value}' for key,value in additions.items() if key not in keys]
if lines: p.write_text(existing.rstrip() + '\n' + '\n'.join(lines) + '\n')
PY
