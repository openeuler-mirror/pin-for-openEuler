#!/bin/bash
# The entrance to build the aarch64 little endian native toolchain.
# Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.

set -e

readonly LOG_PATH="$PWD/../logs"

if [[ -z "$BRANCH" ]]; then
    source $PWD/../config.xml
fi

[ -e "$LOG_PATH/hcc_arm64le_native_patch.log" ] && rm $LOG_PATH/hcc_arm64le_native_patch.log
[ -e "$LOG_PATH/hcc_arm64le_native_build.log" ] && rm $LOG_PATH/hcc_arm64le_native_build.log
[ -e "$LOG_PATH/hcc_arm64le_native_final.log" ] && rm $LOG_PATH/hcc_arm64le_native_final.log
mkdir -p $LOG_PATH

source pre_construction.sh 2>&1 | tee $LOG_PATH/hcc_arm64le_native_patch.log

echo "#-----------------------------------------------"
echo "Now building the hcc_arm64le_native toolchain ..."
echo "The entire build process takes about 18 minutes (build time is related to machine performance), you can view the detailed build log in the ${LOG_PATH} file."
source hcc_aarch64_native_release.sh 2>&1 | tee $LOG_PATH/hcc_arm64le_native_build.log
source hcc_aarch64_native_final.sh 2>&1 | tee $LOG_PATH/hcc_arm64le_native_final.log
echo "Build hcc_arm64le_native toolchain completed!"
