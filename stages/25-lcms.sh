#!/usr/bin/env -S bash -euo pipefail

echo "Download lcms..."
mkdir -p lcms

# renovate: datasource=github-releases depName=mm2/Little-CMS versioning=semver-coerced
_tag='2.16'

curl_tar "https://github.com/mm2/Little-CMS/releases/download/lcms${_tag}/lcms2-${_tag}.tar.gz" lcms 1

case "$TARGET" in
  aarch64*)
    # Patch to enable SSE codepath on aarch64
    patch -F5 -lp1 -d lcms -t <"$PREFIX"/patches/sse2neon.patch
    ;;
esac

sed -i "/subdir('testbed')/d" lcms/meson.build
sed -i "/subdir('plugins')/d" lcms/meson.build

# Remove some superfluous files
rm -rf lcms/{.github,configure.ac,install-sh,depcomp,Makefile.in,config.sub,aclocal.m4,config.guess,ltmain.sh,m4,utils,configure,Projects,doc,testbed,plugins}

# Backup source
bak_src 'lcms'

mkdir -p lcms/build
cd lcms/build

echo "Build lcms..."
meson \
  --errorlogs \
  -Dutils=false \
  -Dsamples=false \
  -Dthreaded=false \
  -Dfastfloat=false \
  ..

ninja -j"$(nproc)"

ninja install
