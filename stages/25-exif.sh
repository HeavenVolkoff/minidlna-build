#!/usr/bin/env -S bash -euo pipefail

echo "Download exif..."
mkdir -p exif

# renovate: datasource=github-releases depName=libexif/libexif
_tag='0.6.25'

curl_tar "https://github.com/libexif/libexif/archive/refs/tags/v${_tag}.tar.gz" exif 1

# Remove unused components
rm -r exif/.*

# Backup source
bak_src 'exif'

cd exif

echo "Build exif..."

autoreconf -fiv

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
  --disable-internal-docs \
  --enable-static \
  --disable-shared \
|| { echo "ERROR: Runing configure"; cat config.log; exit 1; }

make -j"$(nproc)"

make install
