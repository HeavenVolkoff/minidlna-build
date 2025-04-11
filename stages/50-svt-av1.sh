#!/usr/bin/env -S bash -euo pipefail

echo "Download svt-av1..."
mkdir -p svt-av1

# renovate: datasource=gitlab-releases depName=AOMediaCodec/SVT-AV1
_tag='3.0.2'

curl_tar "https://gitlab.com/AOMediaCodec/SVT-AV1/-/archive/v${_tag}/SVT-AV1-v${_tag}.tar.gz" svt-av1 1

# Handbreak patches
curl 'https://github.com/HandBrake/HandBrake/raw/f9e7678/contrib/svt-av1/A01-Enable-Neon-DotProd-and-I8MM-on-Windows.patch' \
  | patch -F5 -lp1 -d svt-av1 -f

# Add flag required by zig to compile some of the AVX512 instructions used by SVT-AV1
sed -i '/-mavx2/a \    -mevex512' svt-av1/Source/Lib/ASM_AVX512/CMakeLists.txt

# Remove some superfluous files
rm -rf svt-av1/{Docs,Config,test,ffmpeg_plugin,gstreamer-plugin,.gitlab*}

# Backup source
bak_src 'svt-av1'

mkdir -p svt-av1/build
cd svt-av1/build

case "$TARGET" in
  x86_64*)
    ENABLE_NASM=On
    ;;
  aarch64*)
    ENABLE_NASM=Off
    ;;
esac

echo "Build svt-av1..."
cmake \
  -DBUILD_ENC=On \
  -DREPRODUCIBLE_BUILDS=On \
  -DSVT_AV1_LTO="$([ "${LTO:-1}" -eq 1 ] && echo On || echo Off)" \
  -DENABLE_NASM="${ENABLE_NASM}" \
  -DCOVERAGE=Off \
  -DBUILD_DEC=Off \
  -DBUILD_APPS=Off \
  -DBUILD_TESTING=Off \
  ..

ninja -j"$(nproc)"

ninja install
