#!/usr/bin/env -S bash -euo pipefail

echo "Download svt-av1..."
mkdir -p svt-av1

curl_tar 'https://gitlab.com/AOMediaCodec/SVT-AV1/-/archive/v1.8.0/SVT-AV1-v1.8.0.tar.gz' svt-av1 1

case "$TARGET" in
  x86_64*)
    ENABLE_NASM=On
    ;;
  aarch64*)
    ENABLE_NASM=Off
    ;;
esac

# Remove some superfluous files
rm -rf svt-av1/{Docs,Config,test,ffmpeg_plugin,gstreamer-plugin,.gitlab*}

# Backup source
bak_src 'svt-av1'

mkdir -p svt-av1/build
cd svt-av1/build

echo "Build svt-av1..."
cmake \
  -DBUILD_ENC=On \
  -DREPRODUCIBLE_BUILDS=On \
  -DSVT_AV1_LTO="$([ "${LTO:-1}" -eq 1 ] && echo On || echo Off)" \
  -DENABLE_NASM="${ENABLE_NASM}" \
  -DCOVERAGE=Off \
  -DBUILD_DEC=Off \
  -DBUILD_APPS=Off \
  -DBUILD_TESTING=Off \
  ..

ninja -j"$(nproc)"

ninja install
