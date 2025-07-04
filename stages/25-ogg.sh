#!/usr/bin/env -S bash -euo pipefail

echo "Download ogg..."
mkdir -p ogg

# renovate: datasource=github-releases depName=xiph/ogg versioning=semver-coerced
_tag='1.3.6'

curl_tar "https://github.com/xiph/ogg/releases/download/v${_tag}/libogg-${_tag}.tar.gz" ogg 1

# Remove some superfluous files
rm -rf ogg/{.github,install-sh,depcomp,Makefile.in,config.sub,aclocal.m4,config.guess,ltmain.sh,m4,configure,doc}

# Backup source
bak_src 'ogg'

mkdir -p ogg/build
cd ogg/build

echo "Build ogg..."
cmake \
  -DINSTALL_DOCS=Off \
  -DBUILD_TESTING=Off \
  -DINSTALL_PKG_CONFIG_MODULE=On \
  -DINSTALL_CMAKE_PACKAGE_MODULE=On \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  ..

ninja -j"$(nproc)"

ninja install
