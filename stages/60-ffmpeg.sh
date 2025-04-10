#!/usr/bin/env -S bash -euo pipefail

echo "Download ffmpeg..."
mkdir -p ffmpeg

_version="7.1.1"

curl_tar "https://github.com/FFmpeg/FFmpeg/archive/refs/tags/n${_version}.tar.gz" ffmpeg 1

# Handbreak patches
for patch in \
  'https://github.com/HandBrake/HandBrake/raw/908b7b4/contrib/ffmpeg/A01-mov-read-name-track-tag-written-by-movenc.patch' \
  'https://github.com/HandBrake/HandBrake/raw/908b7b4/contrib/ffmpeg/A02-movenc-write-3gpp-track-titl-tag.patch' \
  'https://github.com/HandBrake/HandBrake/raw/908b7b4/contrib/ffmpeg/A03-mov-read-3gpp-udta-tags.patch' \
  'https://github.com/HandBrake/HandBrake/raw/908b7b4/contrib/ffmpeg/A04-movenc-write-3gpp-track-names-tags-for-all-available.patch' \
  'https://github.com/HandBrake/HandBrake/raw/908b7b4/contrib/ffmpeg/A05-avformat-mov-add-support-audio-fallback-track-ref.patch' \
  'https://github.com/HandBrake/HandBrake/raw/908b7b4/contrib/ffmpeg/A06-dvdsubdec-fix-processing-of-partial-packets.patch' \
  'https://github.com/HandBrake/HandBrake/raw/908b7b4/contrib/ffmpeg/A07-dvdsubdec-return-number-of-bytes-used.patch' \
  'https://github.com/HandBrake/HandBrake/raw/908b7b4/contrib/ffmpeg/A08-dvdsubdec-use-pts-of-initial-packet.patch' \
  'https://github.com/HandBrake/HandBrake/raw/908b7b4/contrib/ffmpeg/A09-dvdsubdec-add-an-option-to-output-subtitles-with-emp.patch' \
  'https://github.com/HandBrake/HandBrake/raw/908b7b4/contrib/ffmpeg/A10-ccaption_dec-fix-pts-in-real_time-mode.patch' \
  'https://github.com/HandBrake/HandBrake/raw/908b7b4/contrib/ffmpeg/A11-avformat-matroskaenc-return-error-if-aac-extradata-c.patch' \
  'https://github.com/HandBrake/HandBrake/raw/908b7b4/contrib/ffmpeg/A13-libswscale-fix-yuv420p-to-p01xle-color-conversion-bu.patch' \
  'https://github.com/HandBrake/HandBrake/raw/908b7b4/contrib/ffmpeg/A15-Expose-the-unmodified-Dolby-Vision-RPU-T35-buffers.patch' \
  'https://github.com/HandBrake/HandBrake/raw/908b7b4/contrib/ffmpeg/A16-avcodec-amfenc-Add-support-for-on-demand-key-frames.patch' \
  'https://github.com/HandBrake/HandBrake/raw/908b7b4/contrib/ffmpeg/A17-avcodec-amfenc-properly-set-primaries-transfer-and-m.patch' \
  'https://github.com/HandBrake/HandBrake/raw/908b7b4/contrib/ffmpeg/A18-libavcodec-qsvenc-update-has_b_frames-value.patch' \
  'https://github.com/HandBrake/HandBrake/raw/908b7b4/contrib/ffmpeg/A19-libavcodec-qsv-enable-av1-scc.patch' \
  'https://github.com/HandBrake/HandBrake/raw/908b7b4/contrib/ffmpeg/A20-Revert-avcodec-amfenc-GPU-driver-version-check.patch' \
  'https://github.com/HandBrake/HandBrake/raw/908b7b4/contrib/ffmpeg/A21-lavc-pgssubdec-Add-graphic-plane-and-cropping.patch' \
  'https://github.com/HandBrake/HandBrake/raw/908b7b4/contrib/ffmpeg/A23-avformat-movenc-write-iTunEXTC-and-iTunMOVI-metadata.patch' \
  'https://github.com/HandBrake/HandBrake/raw/908b7b4/contrib/ffmpeg/A24-videotoolbox-speedup-decoding.patch' \
  'https://github.com/HandBrake/HandBrake/raw/908b7b4/contrib/ffmpeg/A28-enable-av1_mf-encoder.patch' \
  'https://github.com/HandBrake/HandBrake/raw/908b7b4/contrib/ffmpeg/A30-qsv-fixed-BT2020-BT709-conversion.patch' \
  'https://github.com/FFmpeg/FFmpeg/commit/d1ed5c06e3edc5f2b5f3664c80121fa55b0baa95.patch'; do
  curl "$patch" | patch -F5 -lp1 -d ffmpeg -t
done

# Backup source
bak_src 'ffmpeg'

cd ffmpeg

echo "Build ffmpeg..."

env_specific_arg=()

# CUDA and NVENC
if [ "$(uname -m)" = "${TARGET%%-*}" ] && (case "$TARGET" in *linux*) exit 0 ;; *) exit 1 ;; esac) then
  # zig cc doesn't support compiling cuda code yet, so we use the host clang for it
  # Unfortunatly that means we only suport cuda in the same architecture as the host system
  # https://github.com/ziglang/zig/pull/10704#issuecomment-1023616464
  env_specific_arg+=(
    --nvcc="clang -target ${TARGET}"
    --enable-cuda-llvm
    --enable-ffnvcodec
    --disable-cuda-nvcc
  )
else
  # There are no Nvidia GPU drivers for macOS
  env_specific_arg+=(
    --nvcc=false
    --disable-cuda-llvm
    --disable-ffnvcodec
    --disable-cuda-nvcc
  )
fi

# Architecture specific flags
case "$TARGET" in
  x86_64*)
    env_specific_arg+=(
      --x86asmexe=nasm
      --enable-x86asm
    )
    ;;
  aarch64*)
    env_specific_arg+=(
      --x86asmexe=false
      --enable-vfp
      --enable-neon
      # M1 & N1 Doesn't support i8mm
      --disable-i8mm
    )
    ;;
esac

case "$TARGET" in
  *darwin*)
    env_specific_arg+=(
      --sysroot="${MACOS_SDKROOT:?Missing macOS SDK}"
      # TODO: Metal suport is disabled because no open source compiler is available for it
      # TODO: Maybe try macOS own metal compiler under darling? https://github.com/darlinghq/darling/issues/326
      # TODO: Add support for vulkan (+ libplacebo) on macOS with MoltenVK
      --disable-metal
      --disable-vulkan
      --disable-libshaderc
      --disable-libplacebo
      --enable-coreimage
      --enable-videotoolbox
      --enable-avfoundation
      --enable-audiotoolbox
    )
    ;;
  *linux*)
    env_specific_arg+=(
      --disable-coreimage
      --disable-videotoolbox
      --disable-avfoundation
      --disable-audiotoolbox
      --enable-vaapi
      --enable-libdrm
      --enable-vulkan
      --enable-libshaderc
      --enable-libplacebo
    )
    ;;
esac

# Enable hardware acceleration
case "$TARGET" in
  *darwin*) ;;
    # Apple only support its own APIs for hardware (de/en)coding on macOS
  *)
    env_specific_arg+=(
      --enable-amf
      --enable-libvpl
    )
    ;;
esac

_arch="${TARGET%%-*}"
case "$TARGET" in
  aarch64-darwin*)
    _arch=arm64
    ;;
esac

if [ "${LTO:-1}" -eq 1 ]; then
  env_specific_arg+=(--enable-lto=thin)
fi

if ! ./configure \
  --cpu="$_arch" \
  --arch="$_arch" \
  --prefix="$PREFIX" \
  --target-os="$(case "$TARGET" in *linux*) echo "linux" ;; *darwin*) echo "darwin" ;; esac)" \
  --cc=cc \
  --nm=nm \
  --ar=ar \
  --cxx=c++ \
  --strip=strip \
  --ranlib=ranlib \
  --host-cc=clang \
  --windres="windres" \
  --pkg-config=pkg-config \
  --pkg-config-flags="--static" \
  --disable-debug \
  --disable-doc \
  --disable-htmlpages \
  --disable-indevs \
  --disable-libv4l2 \
  --disable-libwebp \
  --disable-libxcb \
  --disable-libxcb-shape \
  --disable-libxcb-shm \
  --disable-libxcb-xfixes \
  --disable-manpages \
  --disable-mediafoundation \
  --disable-neon-clobber-test \
  --disable-network \
  --disable-nonfree \
  --disable-opengl \
  --disable-openssl \
  --disable-outdevs \
  --disable-parser=avs2 \
  --disable-parser=avs3 \
  --disable-podpages \
  --disable-postproc \
  --disable-programs \
  --disable-schannel \
  --disable-sdl2 \
  --disable-securetransport \
  --disable-shared \
  --disable-txtpages \
  --disable-v4l2-m2m \
  --disable-version3 \
  --disable-xlib \
  --disable-xmm-clobber-test \
  --disable-w32threads \
  --enable-asm \
  --enable-avcodec \
  --enable-avfilter \
  --enable-avformat \
  --enable-bzlib \
  --enable-cross-compile \
  --enable-dotprod \
  --enable-gpl \
  --enable-inline-asm \
  --enable-libdav1d \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libsoxr \
  --enable-libsvtav1 \
  --enable-libtheora \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libvvenc \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libzimg \
  --enable-lzma \
  --enable-opencl \
  --enable-optimizations \
  --enable-pic \
  --enable-postproc \
  --enable-pthreads \
  --enable-swscale \
  --enable-static \
  --enable-zlib \
  "${env_specific_arg[@]}"; then
  cat ffbuild/config.log >&2
  exit 1
fi

# Replace incorrect identified sysctl as enabled on linux
sed -i 's/#define HAVE_SYSCTL 1/#define HAVE_SYSCTL 0/' config.h

make -j"$(nproc)" V=1

make install
