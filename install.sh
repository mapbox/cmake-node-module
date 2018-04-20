#!/usr/bin/env sh

set -euo pipefail

TARGET_NAME=${1:-${npm_package_name}}
BUILD_DIR=${2:-build}
ABI_VERSION=`node -e 'process.stdout.write(process.versions.modules)'`

if [ ! -d ${BUILD_DIR} ]; then
    cmake -H. -B${BUILD_DIR} -DCMAKE_BUILD_TYPE=Release
fi

cmake --build ${BUILD_DIR} --target ${TARGET_NAME}.abi-${ABI_VERSION}
