#!/usr/bin/env -S bash -euo pipefail

case "$TARGET" in
  *darwin*)
    export UNSUPPORTED=1
    exit 1
    ;;
esac

# renovate: datasource=github-releases depName=KhronosGroup/SPIRV-Cross
_tag='1.4.309.0'

# === Vulkan Headers ===

echo "Download vulkan..."
mkdir -p vulkan-headers

curl_tar "https://github.com/KhronosGroup/Vulkan-Headers/archive/refs/tags/vulkan-sdk-${_tag}.tar.gz" vulkan-headers 1

VERSION="$(
  sed -nr \
    's/#define\s+VK_HEADER_VERSION_COMPLETE\s+VK_MAKE_API_VERSION\(\s*[0-9]+,\s*([0-9]+),\s*([0-9]+),\s*VK_HEADER_VERSION\)/\1.\2/p' \
    vulkan-headers/include/vulkan/vulkan_core.h
).$(
  sed -nr \
    's/#define\s+VK_HEADER_VERSION\s+([0-9]+)/\1/p' \
    vulkan-headers/include/vulkan/vulkan_core.h
)"

sed -i '/add_subdirectory(tests)/d'  vulkan-headers/CMakeLists.txt

# Remove some superfluous files
rm -rf vulkan-headers/{.reuse,.github,tests}

# Backup source
bak_src 'vulkan-headers'

mkdir -p vulkan-headers/build
cd vulkan-headers/build

echo "Build vulkan..."
cmake \
  -DBUILD_TESTS=Off \
  ..

ninja -j"$(nproc)"

ninja install

cat >"$PREFIX"/lib/pkgconfig/vulkan.pc <<EOF
prefix=$PREFIX
includedir=\${prefix}/include

Name: vulkan
Version: $VERSION
Description: Vulkan (Headers Only)
Cflags: -I\${includedir}
EOF

# === SPIRV-Cross ===

echo "Download spirv..."
mkdir -p spirv

curl_tar "https://github.com/KhronosGroup/SPIRV-Cross/archive/refs/tags/vulkan-sdk-${_tag}.tar.gz" spirv 1

VERSION="$(
  grep -Po 'set\(spirv-cross-abi-major\s+\K\d+' spirv/CMakeLists.txt
).$(
  grep -Po 'set\(spirv-cross-abi-minor\s+\K\d+' spirv/CMakeLists.txt
).$(
  grep -Po 'set\(spirv-cross-abi-patch\s+\K\d+' spirv/CMakeLists.txt
)"

# Remove some superfluous files
rm -rf spirv/{.github,.reuse,gn,reference,samples,shaders*,tests-other}

# Backup source
bak_src 'spirv'

mkdir -p spirv/build
cd spirv/build

echo "Build spirv..."
cmake \
  -DSPIRV_CROSS_STATIC=On \
  -DSPIRV_CROSS_FORCE_PIC=On \
  -DSPIRV_CROSS_ENABLE_CPP=On \
  -DSPIRV_CROSS_CLI=Off \
  -DSPIRV_CROSS_SHARED=Off \
  -DSPIRV_CROSS_ENABLE_TESTS=Off \
  ..

ninja -j"$(nproc)"

ninja install

cat >"${PREFIX}/lib/pkgconfig/spirv-cross-c-shared.pc" <<EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${prefix}/lib
sharedlibdir=\${prefix}/lib
includedir=\${prefix}/include/spirv_cross

Name: spirv-cross-c-shared
Description: C API for SPIRV-Cross
Version: $VERSION

Requires:
Libs: -L\${libdir} -L\${sharedlibdir} -lspirv-cross-c -lspirv-cross-glsl -lspirv-cross-hlsl -lspirv-cross-reflect -lspirv-cross-msl -lspirv-cross-util -lspirv-cross-core -lstdc++
Cflags: -I\${includedir}
EOF
