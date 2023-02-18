#!/bin/sh

set -e

current_dir="$(dirname "$(realpath "$0")")"
build_dir="${current_dir}/deps/libgit2.build"
install_dir="${current_dir}/deps/libgit2"

cd "${current_dir}"
mkdir -p deps

export CC="${CC:=clang}"

cmake \
    -S "${current_dir}/libs/libgit2" \
    -B "${build_dir}" \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX="${install_dir}" \
    -DCMAKE_C_COMPILER="$CC" \
    -DCMAKE_C_FLAGS="-D_GNU_SOURCE" \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_TESTS=OFF \
    -DBUILD_CLI=OFF \
    -DUSE_SSH=OFF \
    -DUSE_HTTPS=OFF \
    -DUSE_GSSAPI=OFF \
    -DUSE_HTTP_PARSER=builtin \
    -DREGEX_BACKEND=builtin \
    -DUSE_BUNDLED_ZLIB=ON \
    -DSONAME=OFF \
    -DDEPRECATE_HARD=ON \
    -DUSE_NTLMCLIENT=OFF

cmake --build "${build_dir}"

cmake --install "${build_dir}"
