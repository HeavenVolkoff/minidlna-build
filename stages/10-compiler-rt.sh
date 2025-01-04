#!/usr/bin/env -S bash -euo pipefail

# LLVM install path
LLVM_PATH="/usr/lib/llvm-18"

case "$TARGET" in
  *darwin*) ;;
  *)
    export UNSUPPORTED=1
    exit 1
    ;;
esac

# Remove wrapper from PATH, because we need to call the original cmake
PATH="$(echo "${PATH}" | awk -v RS=: -v ORS=: '/\/wrapper^/ {next} {print}')"
export PATH

echo "Download llvm compiler_rt..."

mkdir -p "${LLVM_PATH}/compiler_rt/build"

curl_tar 'https://github.com/llvm/llvm-project/releases/download/llvmorg-18.1.8/cmake-18.1.8.src.tar.xz' \
  "${LLVM_PATH}/cmake" 1
curl_tar 'https://github.com/llvm/llvm-project/releases/download/llvmorg-18.1.8/compiler-rt-18.1.8.src.tar.xz' \
  "${LLVM_PATH}/compiler_rt" 1

# Link cmake files to where compiler_rt expect to find them
ln -s . "${LLVM_PATH}/cmake/modules"
if [ -d "${LLVM_PATH}/cmake/Modules" ]; then
  rsync -a --update --ignore-existing "${LLVM_PATH}/cmake/Modules/" "${LLVM_PATH}/cmake/modules/"
fi

cd "${LLVM_PATH}/compiler_rt/build"

_arch="${TARGET%%-*}"

cmake_config=(
  -GNinja
  -Wno-dev
  -DLLVM_PATH="$LLVM_PATH"
  -DLLVM_CMAKE_DIR="${LLVM_PATH}/cmake/modules"
  -DLLVM_CONFIG_PATH="${LLVM_PATH}/bin/llvm-config"
  -DLLVM_MAIN_SRC_DIR="$LLVM_PATH"
  -DCMAKE_LINKER="$(command -v "${APPLE_TARGET:?}-ld")"
  -DCMAKE_INSTALL_PREFIX="${LLVM_PATH}/lib/clang/18"
  -DCMAKE_TOOLCHAIN_FILE='/srv/toolchain.cmake'
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=Off
  -DCOMPILER_RT_ENABLE_IOS=Off
  -DCOMPILER_RT_BUILD_XRAY=Off
  -DCOMPILER_RT_BUILD_SANITIZERS=Off
  -DDARWIN_macosx_CACHED_SYSROOT="${MACOS_SDKROOT:?Missing macOS SDK path}"
  -DDARWIN_macosx_OVERRIDE_SDK_VERSION="${MACOS_SDK_VERSION:?Missing macOS SDK version}"
  -DDARWIN_PREFER_PUBLIC_SDK=On
  -DDEFAULT_SANITIZER_MIN_OSX_VERSION="${MACOS_SDK_VERSION:?Missing macOS SDK version}"
)

if [ "$_arch" == 'aarch64' ]; then
  cmake_config+=(
    -DDARWIN_osx_ARCHS="arm64"
    -DDARWIN_osx_BUILTIN_ARCHS="arm64"
  )
else
  cmake_config+=(
    -DDARWIN_osx_ARCHS="$_arch"
    -DDARWIN_osx_BUILTIN_ARCHS="$_arch"
  )
fi

cmake "${cmake_config[@]}" ..

ninja -j"$(nproc)"

ninja install

# Symlink clang_rt to arch specific names
while IFS= read -r _lib; do
  _lib_name="$(basename "${_lib}" .a)"
  ln -s "${_lib_name}.a" "$(dirname "${_lib}")/${_lib_name}-${_arch}.a"
  if [ "$_arch" == 'aarch64' ]; then
    ln -s "${_lib_name}.a" "$(dirname "${_lib}")/${_lib_name}-arm64.a"
  fi
done < <(find "${LLVM_PATH}/lib/clang/18/lib/darwin/" -name 'libclang_rt.*')
