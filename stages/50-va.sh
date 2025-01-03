#!/usr/bin/env -S bash -euo pipefail

case "$TARGET" in
  *linux*) ;;
  *)
    export UNSUPPORTED=1
    exit 1
    ;;
esac

echo "Download va..."
mkdir -p va

# renovate: datasource=github-releases depName=intel/libva
_tag='2.22.0'

curl_tar "https://github.com/intel/libva/releases/download/${_tag}/libva-${_tag}.tar.bz2" va 1

rm -rf va/.*

# Backup source
bak_src 'va'

cd va

echo "Build va..."

./configure \
  --host="$TARGET" \
  --build="$(uname -m)-linux-gnu" \
  --prefix="$PREFIX" \
  --with-pic \
  --enable-drm \
  --enable-static \
  --disable-shared \
  --disable-x11 \
  --disable-glx \
  --disable-wayland \
  --disable-docs \
|| { echo "ERROR: Runing configure"; cat config.log; exit 1; }

make -j"$(nproc)"

make install
