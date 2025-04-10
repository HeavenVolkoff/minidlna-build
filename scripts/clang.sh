#!/usr/bin/env sh

set -eu

PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "^${SYSROOT}" | tr '\n' ':' | sed 's/:$//')
export PATH

exec "$(basename "$0")-19" "$@"