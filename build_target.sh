#!/bin/bash
set -e

TARGET_PLATFORM=${1:-android}
echo "=== Building HYPERION-X for Target: $TARGET_PLATFORM ==="

BUILD_DIR="build_$TARGET_PLATFORM"
mkdir -p $BUILD_DIR && cd $BUILD_DIR

if [ "$TARGET_PLATFORM" = "pc" ] || [ "$TARGET_PLATFORM" = "xbox" ]; then
    cmake .. -DCMAKE_BUILD_TYPE=Debug -DPLATFORM=$TARGET_PLATFORM -DCMAKE_TOOLCHAIN_FILE=../toolchain-windows.cmake
elif [ "$TARGET_PLATFORM" = "switch" ] || [ "$TARGET_PLATFORM" = "switch2" ]; then
    cmake .. -DCMAKE_BUILD_TYPE=Debug -DPLATFORM=$TARGET_PLATFORM -DCMAKE_TOOLCHAIN_FILE=../toolchain-switch.cmake
else
    cmake .. -DCMAKE_BUILD_TYPE=Debug -DPLATFORM=$TARGET_PLATFORM
fi

make -j$(nproc)

echo "SUCCESS: HYPERION-X binary compiled for $TARGET_PLATFORM with Debug symbols!"
echo "=== Launching engine with target parameter: $TARGET_PLATFORM ==="
./hyperion_x $TARGET_PLATFORM
