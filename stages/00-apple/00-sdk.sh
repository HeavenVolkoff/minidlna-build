#!/usr/bin/env bash

set -xeuo pipefail

case "$TARGET" in
  *darwin*)
    curl_tar \
      "https://github.com/spacedriveapp/apple-sdks/releases/download/2024.07.24/MacOSX${MACOS_SDK_VERSION:?}.sdk.tar.xz" \
      "${MACOS_SDKROOT:?Missing macOS SDK}" 0
    ;;
  *)
    mkdir -p "${MACOS_SDKROOT:?Missing macOS SDK}"
    ;;
esac
