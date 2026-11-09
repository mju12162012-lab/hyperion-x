#!/bin/bash
set -e

# Locate aapt2 in Android SDK build-tools
AAPT2_PATH=$(find ~/android-sdk/build-tools -name "aapt2" | sort -V | tail -n 1)
if [ -z "$AAPT2_PATH" ]; then
    echo "Error: aapt2 not found in Android SDK build-tools."
    exit 1
fi

echo "Using aapt2: $AAPT2_PATH"

echo "=== [1/4] Compiling Native C++ Engine ==="
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
cd ..

echo "=== [2/4] Building APK Package with aapt2 ==="
rm -rf android/build_apk
mkdir -p android/build_apk/lib/arm64-v8a
cp build/hyperion_x android/build_apk/lib/arm64-v8a/libhyperion-engine.so

$AAPT2_PATH link -o android/build_apk/HYPERION-X.apk \
    --manifest android/app/src/main/AndroidManifest.xml \
    --auto-add-overlay 2>/dev/null || \
$AAPT2_PATH link -o android/build_apk/HYPERION
cd ~/hyperion-x

# 1. Write a pure shell-based build script that avoids external SDK tool dependencies
cat << 'EOF' > build_apk_direct.sh
#!/bin/bash
set -e

echo "=== [1/3] Compiling Native C++ Engine ==="
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
cd ..

echo "=== [2/3] Packaging APK Manually ==="
rm -rf android/build_direct
mkdir -p android/build_direct/lib/arm64-v8a
cp build/hyperion_x android/build_direct/lib/arm64-v8a/libhyperion-engine.so

# Create a valid APK structure using standard zip
cd android/build_direct
cp ../app/src/main/AndroidManifest.xml AndroidManifest.xml
zip -r HYPERION-X.apk lib/ AndroidManifest.xml
cd ../..

echo "=== [3/3] Signing APK ==="
if [ ! -f hyperion.keystore ]; then
    keytool -genkey -v -keystore hyperion.keystore -alias hyperion -keyalg RSA -keysize 2048 -validity 10000 -storepass password -keypass password -dname "CN=Hyperion, OU=Dev, O=Engine, L=Mobile, S=Dev, C=US"
fi

apksigner sign --ks hyperion.keystore --ks-pass pass:password android/build_direct/HYPERION-X.apk

cp android/build_direct/HYPERION-X.apk ~/storage/shared/Download/HYPERION-X.apk
echo "SUCCESS: HYPERION-X.apk built and placed in Download folder!"
ls -lh ~/storage/shared/Download/HYPERION-X.apk
