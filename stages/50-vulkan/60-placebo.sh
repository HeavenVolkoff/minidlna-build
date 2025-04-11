#!/usr/bin/env -S bash -euo pipefail

case "$TARGET" in
  *darwin*)
    export UNSUPPORTED=1
    exit 1
    ;;
esac

echo "Download placebo..."
mkdir -p placebo

curl_tar 'https://github.com/haasn/libplacebo/archive/refs/tags/v7.349.0.tar.gz' placebo 1

# Third party deps
curl_tar 'https://github.com/pallets/jinja/archive/refs/tags/3.1.6.tar.gz' placebo/3rdparty/jinja 1
curl_tar 'https://github.com/pallets/markupsafe/archive/refs/tags/3.0.2.tar.gz' placebo/3rdparty/markupsafe 1
curl_tar 'https://github.com/fastfloat/fast_float/archive/refs/tags/v8.0.2.tar.gz' placebo/3rdparty/fast_float 1

# Remove some superfluous files
rm -rf placebo/{.*,docs,demos}
rm -rf placebo/3rdparty/jinja/{.*,artwork,docs,examples,requirements,scripts,tests}
rm -rf placebo/3rdparty/markupsafe/{.*,bench,docs,requirements,tests}
rm -rf placebo/3rdparty/fast_float/{.*,ci,fuzz,script,tests}

# Backup source
bak_src 'placebo'

mkdir -p placebo/build
cd placebo/build

echo "Build placebo..."

# Only vulkan is supported by FFmpeg when using libplacebo
meson \
  -Dlcms=enabled \
  -Dopengl=disabled \
  -Dvulkan=enabled \
  -Dshaderc=enabled \
  -Dunwind=enabled \
  -Dd3d11=disabled \
  -Dvulkan-registry=/srv/vulkan-headers/registry/vk.xml \
  -Dglslang=disabled \
  -Dgl-proc-addr=disabled \
  -Dvk-proc-addr=disabled \
  -Dfuzz=false \
  -Ddemos=false \
  -Dtests=false \
  -Dbench=false \
  ..

ninja -j"$(nproc)"

ninja install
