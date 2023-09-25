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
readonly PREFIX_NATIVE="$PWD/arm64le_build_dir/$INSTALL_NATIVE"
readonly OUTPUT="$PWD/../../output/$INSTALL_NATIVE"

find $PREFIX_NATIVE -name "*.la" -exec rm -f {} \;

find $PREFIX_NATIVE -name "*.so*" -exec sh -c 'file -ib {} | grep -q "sharedlib" && chrpath --delete {}' \;
echo "End of dir chrpath trim."

find $PREFIX_NATIVE -type f -exec sh -c 'file -ib {} | grep -qE "sharedlib|executable" && /usr/bin/strip --strip-unneeded {}' \;
echo "End of libraries and executables strip."

pushd $PREFIX_NATIVE/.. && chmod 750 $INSTALL_NATIVE -R
tar --format=gnu -czf $OUTPUT/$INSTALL_NATIVE.tar.gz $INSTALL_NATIVE && popd

echo "Build Complete!" && echo "To use this newly-built $INSTALL_NATIVE cross toolchain, add $PREFIX_NATIVE/bin to your PATH!"
