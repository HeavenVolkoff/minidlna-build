#!/usr/bin/env -S bash -euo pipefail

echo "Download flac..."
mkdir -p flac

# renovate: datasource=github-releases depName=xiph/flac versioning=semver-coerced
_tag='1.5.0'

curl_tar "https://github.com/xiph/flac/releases/download/${_tag}/flac-${_tag}.tar.xz" flac 1

# Remove some superfluous files
rm -rf flac/{.*,doc,examples,m4,man,oss-fuzz,test}

# Backup source
bak_src 'flac'

mkdir -p flac/build
cd flac/build

echo "Build flac..."
cmake \
  -DBUILD_CXXLIBS=On \
  -DBUILD_PROGRAMS=Off \
  -DBUILD_EXAMPLES=Off \
  -DBUILD_TESTING=Off \
  -DBUILD_DOCS=Off \
  -DWITH_FORTIFY_SOURCE=On \
  -DWITH_STACK_PROTECTOR=On \
  -DINSTALL_MANPAGES=Off \
  -DINSTALL_PKGCONFIG_MODULES=On \
  -DINSTALL_CMAKE_CONFIG_MODULE=On \
  -DWITH_OGG=On \
  -DBUILD_SHARED_LIBS=Off \
  -DENABLE_MULTITHREADING=On \
  ..

ninja -j"$(nproc)"

ninja install
