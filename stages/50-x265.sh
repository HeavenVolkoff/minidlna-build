#!/usr/bin/env -S bash -euo pipefail

echo "Download x265..."
mkdir -p x265

# renovate: datasource=bitbucket-tags depName=multicoreware/x265_git versioning=semver-coerced
_tag='4.1'

# Need to use master, because the latest release doesn't support optmized aarch64 and it is from 2021
curl_tar "https://bitbucket.org/multicoreware/x265_git/get/${_tag}.tar.gz" x265 1

#  82ff02e  ad1a30a

# Remove some superfluous files
rm -rf x265/build

# Handbreak patches
for patch in \
  'https://github.com/HandBrake/HandBrake/raw/2848a38/contrib/x265/A01-Do-not-set-thread-priority-on-Windows.patch' \
  'https://github.com/HandBrake/HandBrake/raw/2848a38/contrib/x265/A02-Apple-Silicon-tuning.patch' \
  'https://github.com/HandBrake/HandBrake/raw/2848a38/contrib/x265/A03-fix-crash-when-SEI-length-is-variable.patch' \
  'https://github.com/HandBrake/HandBrake/raw/2848a38/contrib/x265/A04-implement-ambient-viewing-environment-sei.patch' \
  'https://github.com/HandBrake/HandBrake/raw/2848a38/contrib/x265/A05-Fix-Dolby-Vision-RPU-memory-management.patch' \
  'https://github.com/HandBrake/HandBrake/raw/2848a38/contrib/x265/A06-Simplify-macOS-cross-compilation.patch' \
  'https://github.com/HandBrake/HandBrake/raw/2848a38/contrib/x265/A07-add-new-matrix-coefficients-from-H.273-v3.patch' \
  'https://bitbucket.org/multicoreware/x265_git/commits/b354c009a60bcd6d7fc04014e200a1ee9c45c167/raw'; do
  curl "$patch" | patch -F5 -lp1 -d x265 -f
done

# Backup source
bak_src 'x265'

cd x265

# Force cmake to use x265Version.txt instead of querying git or hg
sed -i '/set(X265_TAG_DISTANCE/a set(GIT_ARCHETYPE "1")' source/cmake/Version.cmake

echo "Build x265..."

common_config=(
  -DENABLE_PIC=On
  -DENABLE_ASSEMBLY=On
  -DENABLE_CLI=Off
  -DENABLE_TESTS=Off
  -DENABLE_SHARED=Off
  -DENABLE_SVT_HEVC=Off
  -DCMAKE_ASM_NASM_FLAGS=-w-macro-params-legacy
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5
)

case "$TARGET" in
  aarch64*)
    common_config+=(
      -DCROSS_COMPILE_ARM64=ON
      # M1 & N1 Doesn't support i8mm
      -DCROSS_COMPILE_NEON_I8MM=OFF
      -DCROSS_COMPILE_NEON_DOTPROD=ON
    )
    ;;
esac

mkdir 8bit 10bit 12bit

cmake -S source -B 12bit \
  "${common_config[@]}" \
  -DMAIN12=On \
  -DEXPORT_C_API=Off \
  -DHIGH_BIT_DEPTH=On

ninja -C 12bit -j"$(nproc)"

cmake -S source -B 10bit \
  "${common_config[@]}" \
  -DEXPORT_C_API=Off \
  -DHIGH_BIT_DEPTH=On

ninja -C 10bit -j"$(nproc)"

cmake -S source -B 8bit \
  "${common_config[@]}" \
  -DEXTRA_LIB='x265_main10.a;x265_main12.a' \
  -DLINKED_10BIT=On \
  -DLINKED_12BIT=On \
  -DEXTRA_LINK_FLAGS=-L. \
  -DENABLE_HDR10_PLUS=On

ninja -C 8bit -j"$(nproc)"

cd 8bit

# Combine all three into libx265.a
ln -s ../12bit/libx265.a libx265_main12.a
ln -s ../10bit/libx265.a libx265_main10.a
mv libx265.a libx265_main.a

# Must use llvm ar due to mri-script
llvm-ar-19 -M <<EOF
CREATE libx265.a
ADDLIB libx265_main.a
ADDLIB libx265_main10.a
ADDLIB libx265_main12.a
SAVE
END
EOF

ninja install
