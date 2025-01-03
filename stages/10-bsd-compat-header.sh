#!/usr/bin/env -S bash -euo pipefail

case "$TARGET" in
  *-linux-musl) ;;
  *)
    export UNSUPPORTED=1
    exit 1
    ;;
esac

echo "Download bsd-compat-headers..."

mkdir -p bsd-compat-headers

curl_tar "https://gitlab.alpinelinux.org/alpine/aports/-/archive/master/aports-master.tar.gz?path=main/bsd-compat-headers" 'bsd-compat-headers' 3

rm bsd-compat-headers/APKBUILD

# Backup source
bak_src 'bsd-compat-headers'

# Install
mkdir -p "${PREFIX}/include/sys/"
mv bsd-compat-headers/*.h "${PREFIX}/include/sys/"
