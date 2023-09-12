#!/bin/bash
# Download all the required packages.
# Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.

set -e

if [[ -z "$BRANCH" ]]; then
    source $PWD/config.xml
fi

readonly OPEN_SOURCE_PATH="$PWD/../open_source"
readonly CMAKE_NAME="cmake"
readonly OPENSSL_NAME="openssl"
readonly MLIR_NAME="llvm-mlir"
readonly PROTOBUF_NAME="protobuf"
readonly GRPC_NAME="grpc"
readonly CARES_NAME="c-ares"
readonly ABSEIL_NAME="abseil-cpp"
readonly RE2_NAME="re2"
readonly JSONCPP_NAME="jsoncpp"
readonly SERVER_NAME="pin-server"

# Create the open source software directory.
[ ! -d "$OPEN_SOURCE_PATH" ] && mkdir $OPEN_SOURCE_PATH

download() {
    [ -d "$1" ] && rm -rf $1
    echo "Download $1." && git clone -b $BRANCH https://gitee.com/src-openeuler/$1.git
}

# Download packages.
pushd $OPEN_SOURCE_PATH

download $CMAKE_NAME
download $OPENSSL_NAME
download $MLIR_NAME
download $PROTOBUF_NAME
download $GRPC_NAME
download $CARES_NAME
download $ABSEIL_NAME
download $RE2_NAME
download $JSONCPP_NAME
download $SERVER_NAME

popd
echo "Download success!!!"
