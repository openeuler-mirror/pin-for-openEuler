#!/bin/bash
# This script is used to create a temporary directory,
# unzip and patch the source package.
# Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.

set -e

if [[ -z "$BRANCH" ]]; then
    source $PWD/../config.xml
fi

readonly ROOT_BUILD_DIR="$PWD/../.."
readonly ROOT_NATIVE_SRC="$PWD/../../open_source/hcc_arm64le_native_build_src"
readonly OUTPUT="$PWD/../../output/$INSTALL_NATIVE"

# Clear history build legacy files.
clean() {
    [ -n "$ROOT_NATIVE_SRC" ] && rm -rf $ROOT_NATIVE_SRC
    [ -n "$OUTPUT" ] && rm -rf $OUTPUT
    mkdir -p $ROOT_NATIVE_SRC $OUTPUT
}

# Clean the build directory.
clean

# Unzip the source package and copy the source files.
tar -xzf $ROOT_BUILD_DIR/open_source/cmake/$CMAKE.tar.gz -C $ROOT_NATIVE_SRC
tar -xzf $ROOT_BUILD_DIR/open_source/openssl/$OPENSSL.tar.gz -C $ROOT_NATIVE_SRC
tar -xf $ROOT_BUILD_DIR/open_source/llvm-mlir/$MLIR.tar.xz -C $ROOT_NATIVE_SRC
tar -xzf $ROOT_BUILD_DIR/open_source/protobuf/protobuf-all-3.14.0.tar.gz -C $ROOT_NATIVE_SRC
tar -xzf $ROOT_BUILD_DIR/open_source/grpc/$GRPC.tar.gz -C $ROOT_NATIVE_SRC
tar -xzf $ROOT_BUILD_DIR/open_source/c-ares/$CARES.tar.gz -C $ROOT_NATIVE_SRC
tar -xzf $ROOT_BUILD_DIR/open_source/abseil-cpp/$ABSEIL.tar.gz -C $ROOT_NATIVE_SRC
tar -xzf $ROOT_BUILD_DIR/open_source/re2/2021-11-01.tar.gz -C $ROOT_NATIVE_SRC
tar -xzf $ROOT_BUILD_DIR/open_source/jsoncpp/$JSONCPP.tar.gz -C $ROOT_NATIVE_SRC
tar -xzf $ROOT_BUILD_DIR/open_source/pin-server/$SERVER.tar.gz -C $ROOT_NATIVE_SRC

apply_patch() {
    cd $ROOT_NATIVE_SRC/$2
    for file in $(grep -ne ^Patch[0-9]*:.*\.patch $ROOT_BUILD_DIR/open_source/$1/$1.spec | awk '{print $2}'); do
        patch --fuzz=0 -p1 <$ROOT_BUILD_DIR/open_source/$1/$file
    done
    cd -
}

apply_patch cmake $CMAKE
apply_patch openssl $OPENSSL
apply_patch llvm-mlir $MLIR
apply_patch protobuf $PROTOBUF
apply_patch grpc $GRPC
apply_patch c-ares $CARES
rm -rf $ROOT_NATIVE_SRC/$GRPC/third_party/cares/cares
mv $ROOT_NATIVE_SRC/$CARES $ROOT_NATIVE_SRC/$GRPC/third_party/cares/cares

apply_patch abseil-cpp $ABSEIL
rm -rf $ROOT_NATIVE_SRC/$GRPC/third_party/abseil-cpp
mv $ROOT_NATIVE_SRC/$ABSEIL $ROOT_NATIVE_SRC/$GRPC/third_party/abseil-cpp

apply_patch re2 $RE2
rm -rf $ROOT_NATIVE_SRC/$GRPC/third_party/re2
mv $ROOT_NATIVE_SRC/$RE2 $ROOT_NATIVE_SRC/$GRPC/third_party/re2

apply_patch jsoncpp $JSONCPP
apply_patch pin-server $SERVER

chmod 777 $ROOT_NATIVE_SRC -R
