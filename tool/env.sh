# Source this file from any working directory; do not execute it as a child shell.
export PATH="/workspace/.tools/flutter/bin:/workspace/.tools/android-sdk/platform-tools:/workspace/.tools/android-sdk/cmdline-tools/19.0/bin:$PATH"
export PUB_CACHE=/workspace/.tools/pub-cache
export ANDROID_HOME=/workspace/.tools/android-sdk
export ANDROID_SDK_ROOT=/workspace/.tools/android-sdk
export ANDROID_USER_HOME=/workspace/.tools/android-user
export GRADLE_USER_HOME=/workspace/.tools/gradle
export LD_LIBRARY_PATH="/workspace/.tools/native${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export FLUTTER_SUPPRESS_ANALYTICS=true
export DART_SUPPRESS_ANALYTICS=true

if [[ -x /workspace/.tools/jdk/bin/javac ]]; then
  export JAVA_HOME=/workspace/.tools/jdk
  export PATH="$JAVA_HOME/bin:$PATH"
fi

# Trust the platform CA bundle (including its egress proxy CA), with TLS checks enabled.
if [[ -f /etc/ssl/certs/java/cacerts && "${JAVA_TOOL_OPTIONS:-}" != *"-Djavax.net.ssl.trustStore="* ]]; then
  export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:+$JAVA_TOOL_OPTIONS }-Djavax.net.ssl.trustStore=/etc/ssl/certs/java/cacerts"
fi
