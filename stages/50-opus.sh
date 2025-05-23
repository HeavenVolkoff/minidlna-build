#!/usr/bin/env -S bash -euo pipefail

echo "Download opus..."
mkdir -p opus

# renovate: datasource=github-tags depName=xiph/opus versioning=semver-coerced
_tag='1.5.2'

curl_tar "https://downloads.xiph.org/releases/opus/opus-${_tag}.tar.gz" opus 1

# Remove unused components
rm -rf opus/{.github,CMakeLists.txt,config.sub,aclocal.m4,config.guess,cmake,doc,Makefile.in,tests,ltmain.sh,m4,configure}

# Backup source
bak_src 'opus'

mkdir -p opus/build
cd opus/build

echo "Build opus..."
meson \
  -Dintrinsics=enabled \
  -Ddocs=disabled \
  -Dtests=disabled \
  -Dcustom-modes=true \
  -Dextra-programs=disabled \
  ..

ninja -j"$(nproc)"

ninja install
