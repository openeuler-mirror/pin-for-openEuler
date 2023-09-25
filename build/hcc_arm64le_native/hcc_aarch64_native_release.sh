#!/bin/bash
# This file contains the complete sequence of commands
# to build the toolchain, including the configuration
# options and compilation processes.
# Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.

set -e

if [[ -z "$BRANCH" ]]; then
    source $PWD/../config.xml
fi

# Target root directory, should be adapted according to your environment.
readonly ROOT_NATIVE_DIR="$PWD/arm64le_build_dir"
readonly ROOT_NATIVE_SRC="$PWD/../../open_source/hcc_arm64le_native_build_src"
readonly PREFIX_NATIVE="$PWD/arm64le_build_dir/$INSTALL_NATIVE"
readonly PREFIX_GRPC="$PWD/arm64le_build_dir/grpc"
readonly PREFIX_PROTOBUF="$PWD/arm64le_build_dir/protobuf"
readonly PREFIX_MLIR="$PWD/arm64le_build_dir/llvm-mlir"
readonly PREFIX_OPENSSL="$PWD/arm64le_build_dir/openssl"
readonly PREFIX_JSONCPP="$PWD/arm64le_build_dir/jsoncpp"
readonly OUTPUT="$PWD/../../output/$INSTALL_NATIVE"
readonly PARALLEL=$(grep ^processor /proc/cpuinfo | wc -l)
readonly HOST="aarch64-linux-gnu"
readonly BUILD=$HOST
readonly TARGET=$HOST

declare -x SECURE_CFLAGS="-O2 -fPIC -Wall -fstack-protector-strong -D_FORTIFY_SOURCE=2 -Wl,-z,relro,-z,now,-z,noexecstack -Wtrampolines -mlittle-endian -march=armv8-a"
declare -x SECURE_LDFLAGS="-z relro -z now -z noexecstack"
declare -x FCFLAGS="$SECURE_CFLAGS"

# Create an empty directory.
create_directory() {
    while [ $# != 0 ]; do
        [ -n "$1" ] && rm -rf $1
        mkdir -p $1
        shift
    done
}

create_directory $ROOT_NATIVE_DIR/obj $PREFIX_NATIVE $PREFIX_GRPC $PREFIX_PROTOBUF $PREFIX_MLIR $PREFIX_OPENSSL $PREFIX_JSONCPP $OUTPUT $ROOT_NATIVE_DIR/obj/build-llvm-mlir ${ROOT_NATIVE_DIR}/obj/build-jsoncpp $ROOT_NATIVE_DIR/obj/build-grpc $ROOT_NATIVE_DIR/obj/build-protobuf $ROOT_NATIVE_DIR/obj/build-protobuf $ROOT_NATIVE_DIR/obj/build-server $ROOT_NATIVE_DIR/obj/build-openssl $ROOT_NATIVE_DIR/obj/build-cmake

echo "Building openssl for cmake..." && pushd $ROOT_NATIVE_DIR/obj/build-openssl
cp -rf $ROOT_NATIVE_SRC/$OPENSSL/* .
LDFLAGS="${SECURE_LDFLAGS}" CFLAGS="${SECURE_CFLAGS}" CXXFLAGS="${SECURE_CFLAGS}" ./Configure --prefix=$PREFIX_OPENSSL --openssldir=$PREFIX_OPENSSL enable-ec_nistp_64_gcc_128 zlib enable-camellia enable-seed enable-rfc3779 enable-sctp enable-cms enable-md2 enable-rc5 enable-ssl3 enable-ssl3-method enable-weak-ssl-ciphers no-mdc2 no-ec2m enable-sm2 enable-sm3 enable-sm4 enable-tlcp shared linux-aarch64 -Wa,--noexecstack -DPURIFY '-DDEVRANDOM="\"/dev/urandom\""'
make -j $PARALLEL && make install && popd

export OPENSSL_ROOT_DIR=$PREFIX_OPENSSL
export PATH=$PREFIX_OPENSSL/bin:$PATH
export LD_LIBRARY_PATH=$PREFIX_OPENSSL/lib
export CPLUS_INCLUDE_PATH=$PREFIX_OPENSSL/include

echo "Building cmake..." && pushd $ROOT_NATIVE_DIR/obj/build-cmake
$ROOT_NATIVE_SRC/$CMAKE/configure --prefix=$ROOT_NATIVE_DIR/obj/build-cmake
make -j $PARALLEL && make install && popd
export PATH=$ROOT_NATIVE_DIR/obj/build-cmake/bin:$PATH

echo "Building mlir..." && pushd $ROOT_NATIVE_DIR/obj/build-llvm-mlir
cmake -G"Unix Makefiles" $ROOT_NATIVE_SRC/$MLIR/llvm -DLLVM_ENABLE_RTTI=ON -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=ON -DLLVM_ENABLE_PROJECTS="mlir" -DLLVM_TARGETS_TO_BUILD="AArch64" -DCMAKE_INSTALL_PREFIX=$PREFIX_MLIR
make -j $PARALLEL && make install && popd
export PATH=$PREFIX_MLIR/bin:$PATH
cp $PREFIX_MLIR/bin/mlir-tblgen /usr/bin

echo "Building protobuf..." && pushd $ROOT_NATIVE_DIR/obj/build-protobuf
cp -rf $ROOT_NATIVE_SRC/$PROTOBUF/* .
sed -i '37{s/$/ -I \/usr\/share\/aclocal/}' autogen.sh && ./autogen.sh && ./configure --prefix=$PREFIX_PROTOBUF
make -j && make install && popd

echo "Building grpc..." && pushd "${ROOT_NATIVE_DIR}/obj/build-grpc"
cmake -G "Unix Makefiles" $ROOT_NATIVE_SRC/$GRPC -DCMAKE_BUILD_TYPE=Release -DgRPC_INSTALL=ON -DgRPC_CARES_PROVIDER=module -DgRPC_PROTOBUF_PROVIDER=package -DgRPC_SSL_PROVIDER=package -DgRPC_RE2_PROVIDER=module -DgRPC_ABSL_PROVIDER=module -DCMAKE_INSTALL_PREFIX=$PREFIX_GRPC -DProtobuf_INCLUDE_DIR=$PREFIX_PROTOBUF/include -DProtobuf_LIBRARY=$PREFIX_PROTOBUF/lib/libprotobuf.so -DProtobuf_PROTOC_LIBRARY=$PREFIX_PROTOBUF/lib/libprotoc.so -DProtobuf_PROTOC_EXECUTABLE=$PREFIX_PROTOBUF/bin/protoc -DBUILD_DEPS=ON -DBUILD_SHARED_LIBS=ON
make -j $PARALLEL && make install && popd

echo "Building jsoncpp..." && pushd "${ROOT_NATIVE_DIR}/obj/build-jsoncpp"
cmake -G"Unix Makefiles" $ROOT_NATIVE_SRC/$JSONCPP -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$PREFIX_JSONCPP
make -j $PARALLEL && make install && popd

export LD_LIBRARY_PATH=$PREFIX_GRPC/lib:$PREFIX_PROTOBUF/lib:$LD_LIBRARY_PATH
export CPLUS_INCLUDE_PATH=$PREFIX_PROTOBUF/include:$PREFIX_JSONCPP/include

echo "Building pin-server..." && pushd "${ROOT_NATIVE_DIR}/obj/build-server"
cmake -G"Unix Makefiles" $ROOT_NATIVE_SRC/$SERVER -DCMAKE_PREFIX_PATH="$PREFIX_PROTOBUF;$PREFIX_GRPC;$PREFIX_JSONCPP" -DCMAKE_INSTALL_PREFIX=$PREFIX_NATIVE
make -j $PARALLEL && make install && popd
cp ${ROOT_NATIVE_DIR}/obj/build-server/lib/CMakeFiles/obj.MLIRServerAPI.dir/PluginAPI/PluginServerAPI.cpp.o $PREFIX_NATIVE/lib
cp -r ${ROOT_NATIVE_DIR}/obj/build-server/CMakeFiles/pin_server.dir/lib/* $PREFIX_NATIVE/lib
cp ${ROOT_NATIVE_DIR}/obj/build-server/libplg_grpc_proto.a $PREFIX_NATIVE/lib
