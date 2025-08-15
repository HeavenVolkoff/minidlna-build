#!/usr/bin/env -S bash -euo pipefail

echo "Download zimg..."
mkdir -p zimg

# renovate: datasource=github-releases depName=sekrit-twc/zimg
_tag='3.0.6'

curl_tar "https://github.com/sekrit-twc/zimg/archive/refs/tags/release-${_tag}.tar.gz" zimg 1

sed -i '/^dist_example_DATA/,/src\/testcommon\/win32_bitmap.h/d;' zimg/Makefile.am

# Remove unused components
rm -r zimg/{doc,_msvc,test,src/{testapp,testcommon}}

# Backup source
bak_src 'zimg'

cd zimg

echo "Build zimg..."

./autogen.sh

# shellcheck disable=SC2046
./configure \
  $(
    case "$TARGET" in
      *linux*)
        echo "--host=${TARGET}"
        ;;
      x86_64-darwin* | aarch64-darwin*)
        echo "--host=${APPLE_TARGET}"
        ;;
    esac
  ) \
  --build="$(uname -m)-linux-gnu" \
  --prefix="$PREFIX" \
  --with-pic \
  --enable-static \
  --disable-debug \
  --disable-shared \
  --disable-testapp \
  --disable-example \
  --disable-unit-test \
|| { echo "ERROR: Runing configure"; cat config.log; exit 1; }

make -j"$(nproc)"

make install
