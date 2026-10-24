#!/usr/bin/env bash
set -euo pipefail
cd /workspace/tudoaki
# Released stable toolchain; stored outside the application checkout.
version=3.35.7
sdk_root=/workspace/.tools/flutter
if [[ ! -x "$sdk_root/bin/flutter" ]]; then
  mkdir -p /workspace/.tools
  if [[ -e "$sdk_root" ]]; then
    echo 'Existing incomplete Flutter directory found; inspect before replacing.' >&2
    exit 1
  fi
  git clone --depth 1 --branch "$version" https://github.com/flutter/flutter.git "$sdk_root"
fi
expected_commit=adc901062556672b4138e18a4dc62a4be8f4b3c2
if [[ "$(git -C "$sdk_root" rev-parse HEAD)" != "$expected_commit" ]]; then
  echo 'Unexpected Flutter revision; refusing to use a different toolchain.' >&2
  exit 1
fi
export PATH="$sdk_root/bin:$PATH"
export PUB_CACHE=/workspace/.tools/pub-cache
export FLUTTER_SUPPRESS_ANALYTICS=true
export DART_SUPPRESS_ANALYTICS=true
mkdir -p /workspace/.tools/native
if [[ ! -e /workspace/.tools/native/libsqlite3.so ]]; then
  test -f /usr/lib/x86_64-linux-gnu/libsqlite3.so.0
  ln -s /usr/lib/x86_64-linux-gnu/libsqlite3.so.0 /workspace/.tools/native/libsqlite3.so
fi
bash tool/setup_jdk.sh
source tool/env.sh
flutter config --jdk-dir=/workspace/.tools/jdk
flutter --version
flutter config --no-analytics
flutter precache --android
bash tool/setup_android.sh
if [[ -f pubspec.lock ]]; then
  flutter pub get --enforce-lockfile
else
  flutter pub get
fi
