#!/usr/bin/env -S bash -euo pipefail

echo "Download id3tag..."
mkdir -p id3tag

# renovate: datasource=git-tags depName=https://codeberg.org/tenacityteam/libid3tag.git
_tag='0.16.3'

curl_tar "https://codeberg.org/tenacityteam/libid3tag/archive/${_tag}.tar.gz" id3tag 1

# Remove some superfluous files
rm -rf id3tag/.*

# Backup source
bak_src 'id3tag'

mkdir -p id3tag/build
cd id3tag/build

echo "Build id3tag..."
cmake \
  -DBUILD_SHARED_LIBS=Off \
  ..

ninja -j"$(nproc)"

ninja install
