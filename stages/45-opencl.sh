#!/usr/bin/env -S bash -euo pipefail
echo "Download opencl headers..."

# renovate: datasource=github-releases depName=KhronosGroup/OpenCL-ICD-Loader
_tag='2024.10.24'

# === OpenCL Headers ===

mkdir -p opencl-headers

curl_tar "https://github.com/KhronosGroup/OpenCL-Headers/archive/refs/tags/v${_tag}.tar.gz" opencl-headers 1

# Remove some superfluous files
rm -rf opencl-headers/{.github,tests}

# Backup source
bak_src 'opencl-headers'

# Install
mkdir -p "${PREFIX}/include"
mv 'opencl-headers/CL' "${PREFIX}/include/"

# === OpenCL ICD Loader ===

echo "Download opencl..."

mkdir -p opencl

curl_tar "https://github.com/KhronosGroup/OpenCL-ICD-Loader/archive/refs/tags/v${_tag}.tar.gz" opencl 1

# Remove some superfluous files
rm -rf opencl/{.github,test}

# Backup source
bak_src 'opencl'

mkdir -p opencl/build
cd opencl/build

echo "Build opencl..."
cmake \
  -DOPENCL_ICD_LOADER_PIC=On \
  -DOPENCL_ICD_LOADER_HEADERS_DIR="${PREFIX}/include" \
  -DBUILD_TESTING=Off \
  -DENABLE_OPENCL_LAYERINFO=Off \
  -DOPENCL_ICD_LOADER_BUILD_TESTING=Off \
  -DOPENCL_ICD_LOADER_BUILD_SHARED_LIBS=Off \
  ..

ninja -j"$(nproc)"

ninja install

case "$TARGET" in
  *linux*)
    LIBS='-lOpenCL'
    LIBS_P='-pthread -ldl'
    ;;
  *darwin*)
    LIBS='-lOpenCL'
    LIBS_P='-pthread -framework OpenCL'
    ;;
esac

mkdir -p "${PREFIX}/lib/pkgconfig"
cat <<EOF >"${PREFIX}/lib/pkgconfig/OpenCL.pc"
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: OpenCL
Description: OpenCL ICD Loader
Version: 9999
Cflags: -I\${includedir} -DCL_TARGET_OPENCL_VERSION=120
Libs: -L\${libdir} $LIBS
Libs.private: $LIBS_P
EOF

if [ -f "${PREFIX}/lib/OpenCL.a" ] && ! [ -f "${PREFIX}/lib/libOpenCL.a" ]; then
  ln -s OpenCL.a "${PREFIX}/lib/libOpenCL.a"
fi
