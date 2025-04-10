#!/usr/bin/env -S bash -euo pipefail

case "$TARGET" in
  *darwin*)
    # MacOS SDK ships sqlite
    export UNSUPPORTED=1
    exit 1
    ;;
esac

echo "Download sqlite..."
mkdir -p sqlite

# renovate: datasource=github-releases depName=sqlite/sqlite
_tag='3.47.2'

curl_tar "https://github.com/sqlite/sqlite/archive/refs/tags/version-${_tag}.tar.gz" sqlite 1

# Remove unused components
rm -r sqlite/{.*,art,doc,test}

# Backup source
bak_src 'sqlite'

cd sqlite

echo "Build sqlite..."

autoreconf --verbose --install --force

export CFLAGS="${CFLAGS:-} \
  -DSQLITE_ENABLE_COLUMN_METADATA=1 \
  -DSQLITE_ENABLE_UNLOCK_NOTIFY \
  -DSQLITE_ENABLE_DBSTAT_VTAB=1 \
  -DSQLITE_ENABLE_FTS3_TOKENIZER=1 \
  -DSQLITE_ENABLE_FTS3_PARENTHESIS \
  -DSQLITE_SECURE_DELETE \
  -DSQLITE_ENABLE_STMTVTAB \
  -DSQLITE_ENABLE_STAT4 \
  -DSQLITE_MAX_VARIABLE_NUMBER=250000 \
  -DSQLITE_MAX_EXPR_DEPTH=10000 \
  -DSQLITE_ENABLE_MATH_FUNCTIONS"

# shellcheck disable=SC2046
./configure \
  $(
    case "$TARGET" in
      *linux*)
        echo "--host=${TARGET}"
        ;;
      x86_64-darwin* | aarch64-darwin*)
        echo "--host=${APPLE_TARGET}"
        ;;
    esac
  ) \
  --build="$(uname -m)-linux-gnu" \
  --prefix="$PREFIX" \
  --enable-static \
  --enable-fts3 \
  --enable-fts4 \
  --enable-fts5 \
  --enable-rtree \
  --disable-shared

make TCC=cc BCC=clang -j"$(nproc)" lib_install sqlite3.h sqlite3.pc

install -d "${PREFIX}/include"
install -m 0644 sqlite3.h "${PREFIX}/include"
install -m 0644 src/sqlite3ext.h "${PREFIX}/include"
install -d "${PREFIX}/lib/pkgconfig"
install -m 0644 sqlite3.pc "${PREFIX}/lib/pkgconfig"
