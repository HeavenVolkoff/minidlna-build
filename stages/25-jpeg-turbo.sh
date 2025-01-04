#!/usr/bin/env -S bash -euo pipefail

echo "Download jpeg-turbo..."
mkdir -p jpeg-turbo

# renovate: datasource=github-releases depName=libjpeg-turbo/libjpeg-turbo
_tag='3.1.0'

curl_tar "https://github.com/libjpeg-turbo/libjpeg-turbo/archive/refs/tags/${_tag}.tar.gz" jpeg-turbo 1

# Remove some superfluous files
rm -rf jpeg-turbo/{.*,testimages,sharedlib,java,fuzz,win}

# Backup source
bak_src 'jpeg-turbo'

mkdir -p jpeg-turbo/build
cd jpeg-turbo/build

echo "Build jpeg-turbo..."
cmake \
  -DWITH_SIMD=On \
  -DREQUIRE_SIMD=On \
  -DENABLE_STATIC=On \
  -DWITH_FUZZ=Off \
  -DWITH_JAVA=Off \
  -DWITH_JPEG7=Off \
  -DWITH_JPEG8=Off \
  -DENABLE_SHARED=Off \
  -DWITH_TURBOJPEG=Off \
  ..

ninja -j"$(nproc)"

ninja install
