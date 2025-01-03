#!/usr/bin/env -S bash -euo pipefail

echo "Download minidlna..."
mkdir -p minidlna

# renovate: depName=https://github.com/NathanaelA/minidlna.git
_commit='33da136af3e71abb5cd6250720c522e9deb8cf1f'

# Using master due to aarch64 improvements
curl_tar "https://github.com/NathanaelA/minidlna/archive/${_commit}.tar.gz" minidlna 1

for patch in "$PREFIX"/patches/*; do
  patch -F5 -lp1 -d minidlna -t <"$patch"
done

# Remove unused components
rm -r minidlna/.*

# Backup source
bak_src 'minidlna'

cd minidlna

echo "Build minidlna..."

export CFLAGS="${CFLAGS:-} $(pkg-config --static --cflags libavformat libavcodec libavutil libavfilter)"
export LDFLAGS="${LDFLAGS:-} $(pkg-config --static --libs libavformat libavcodec libavutil libavfilter)"

./autogen.sh

# shellcheck disable=SC2046
./configure \
  $(
    case "$TARGET" in
      *linux*)
        echo "--host=${TARGET}"
        echo '--enable-static'
        ;;
      x86_64-darwin* | aarch64-darwin*)
        echo "--host=${APPLE_TARGET}"
        ;;
    esac
  ) \
  --build="$(uname -m)-linux-gnu" \
  --prefix="${OUT}" \
  --enable-lto \
  --disable-shared \
  --enable-thumbnail \
  --with-log-path="$(case "$TARGET" in *linux*) echo '/var/log' ;; *darwin*) echo '/usr/local/var/log' ;; esac)" \
  --with-db-path="$(case "$TARGET" in *linux*) echo '/var/cache/minidlna' ;; *darwin*) echo '/usr/local/var/cache/minidlna' ;; esac)" \
  --with-os-name="$(case "$TARGET" in *linux*) echo 'Linux' ;; *darwin*) echo 'macOS' ;; esac)" \
  --with-os-version="$(case "$TARGET" in *linux*) uname -r ;; *darwin*) sw_vers --productVersion ;; esac)" \
  --with-os-url="$(case "$TARGET" in *linux*) echo 'http://www.linux.org' ;; *darwin*) echo 'http://www.apple.com' ;; esac)" \
|| { echo "ERROR: Running configure"; cat config.log; exit 1; }

make -j"$(nproc)"

make install
