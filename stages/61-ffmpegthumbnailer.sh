#!/usr/bin/env -S bash -euo pipefail

echo "Download ffmpegthumbnailer..."
mkdir -p ffmpegthumbnailer

# renovate: datasource=gitlab-releases depName=dirkvdb/ffmpegthumbnailer
_tag='2.2.3'

curl_tar "https://github.com/dirkvdb/ffmpegthumbnailer/archive/refs/tags/${_tag}.tar.gz" ffmpegthumbnailer 1

sed -i '/ADD_EXECUTABLE(ffmpegthumbnailer main.cpp)/,/install(TARGETS ffmpegthumbnailer ${STATIC_LIB} ${SHARED_LIB}/c\install(TARGETS ${STATIC_LIB}' ffmpegthumbnailer/CMakeLists.txt
sed -i '/set_target_properties(libffmpegthumbnailerstatic PROPERTIES/,/OUTPUT_NAME ffmpegthumbnailer/a\        PUBLIC_HEADER "${LIB_HDRS}"' ffmpegthumbnailer/CMakeLists.txt

# Remove some superfluous files
rm -rf ffmpegthumbnailer/{.*,dist,gfx,test,thunar\ files}

# Backup source
bak_src 'ffmpegthumbnailer'

mkdir -p ffmpegthumbnailer/build
cd ffmpegthumbnailer/build

echo "Build ffmpegthumbnailer..."
cmake \
  -DENABLE_STATIC=ON \
  -DENABLE_SHARED=OFF \
  -DENABLE_TESTS=OFF \
  -DENABLE_GIO=OFF \
  -DENABLE_THUMBNAILER=OFF \
  -DSANITIZE_ADDRESS=OFF \
  ..

ninja -j"$(nproc)"

ninja install
