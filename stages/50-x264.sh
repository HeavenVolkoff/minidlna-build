#!/usr/bin/env -S bash -euo pipefail

echo "Download x264..."
mkdir -p x264

# Using master due to aarch64 improvements
curl_tar 'https://code.videolan.org/videolan/x264/-/archive/c1962404/x264.tar.bz2' x264 1

# Some minor fixes to x264's pkg-config
for patch in \
  'https://github.com/msys2/MINGW-packages/raw/f4bd368/mingw-w64-x264/0001-beautify-pc.all.patch' \
  'https://github.com/msys2/MINGW-packages/raw/f4bd368/mingw-w64-x264/0003-pkgconfig-add-Cflags-private.patch'; do
  curl "$patch" | patch -F5 -lp1 -d x264 -t
done

case "$TARGET" in
  *darwin*)
    # Forcing alignment change is not supported by the apple linker
    sed -i "/^if cc_check '' '' '' '__attribute__((force_align_arg_pointer))' ; then/,/^fi/d;" x264/configure
    ;;
esac

# Remove some superfluous files
rm -rf x264/doc

# Backup source
bak_src 'x264'

cd x264

echo "Build x264..."

# x264 is only compatible with windres, so use compat script
# shellcheck disable=SC2046
env RC="$WINDRES" ./configure \
  --prefix="$PREFIX" \
  $(
    if [ "${LTO:-1}" -eq 1 ]; then
      echo '--enable-lto'
    fi

    case "$TARGET" in
      *linux*)
        echo "--host=${TARGET%%-*}-linux-gnu"
        echo '--disable-win32thread'
        ;;
      *windows*)
        echo "--host=${TARGET%%-*}-windows-mingw64"
        ;;
      x86_64-darwin*)
        echo "--host=${APPLE_TARGET}"
        echo '--disable-win32thread'
        ;;
      aarch64-darwin*)
        echo "--host=${APPLE_TARGET}"
        echo '--disable-win32thread'
        ;;
    esac
  ) \
  --enable-pic \
  --enable-static \
  --bit-depth=all \
  --chroma-format=all \
  --disable-cli

make -j"$(nproc)"

make install
