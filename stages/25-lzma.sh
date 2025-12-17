#!/usr/bin/env -S bash -euo pipefail

echo "Download lzma..."
mkdir -p lzma

# renovate: datasource=github-releases depName=tukaani-project/xz
_tag='5.8.2'

curl_tar "https://github.com/tukaani-project/xz/releases/download/v${_tag}/xz-${_tag}.tar.xz" lzma 1

case "$TARGET" in
  *darwin*)
    mkdir -p "${PREFIX:?Missing prefix}/include/"
    # MacOS ships liblzma, however it doesn't include its headers
    cp -avr lzma/src/liblzma/api/{lzma,lzma.h} "${PREFIX}/include/"
    exit 0
    ;;
esac

# Remove some superfluous files
shopt -s extglob
rm -rf lzma/{.github,config.h.in,dos,Makefile.in,configure.ac,aclocal.m4,debug,lib,doxygen,windows,build-aux,m4,configure,tests,po,doc/examples,doc/*.!(txt),po4a}

# Ignore i18n compilation
sed -i 's/if(ENABLE_NLS)/if(FALSE)/' lzma/CMakeLists.txt
sed -i 's/if(GETTEXT_FOUND)/if(FALSE)/' lzma/CMakeLists.txt

# Backup source
bak_src 'lzma'

mkdir -p lzma/build
cd lzma/build

echo "Build lzma..."

cmake \
  -DXZ_SMALL=On \
  -DCMAKE_SKIP_INSTALL_ALL_DEPENDENCY=On \
  -DXZ_NLS=Off \
  -DXZ_DOC=Off \
  -DXZ_TOOL_XZ=Off \
  -DXZ_DOXYGEN=Off \
  -DXZ_TOOL_XZDEC=Off \
  -DXZ_TOOL_XZDEC=Off \
  -DXZ_TOOL_LZMADEC=Off \
  -DXZ_TOOL_SCRIPTS=Off \
  -DXZ_TOOL_LZMAINFO=Off \
  -DXZ_TOOL_SYMLINKS=Off \
  -DXZ_MICROLZMA_ENCODER=Off \
  -DXZ_MICROLZMA_DECODER=Off \
  -DXZ_TOOL_SYMLINKS_LZMA=Off \
  ..

ninja -j"$(nproc)" liblzma

ninja install
