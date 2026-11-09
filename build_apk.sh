#!/bin/bash
set -e

# Locate aapt2 (check system path or Android SDK build-tools)
AAPT2_BIN=$(command -v aapt2 || find ~/android-sdk/build-tools -name "aapt2" | head -n 1)
if [ -z "$AAPT2_BIN" ]; then
    echo "Error: aapt2 could not be found. Please ensure android-tools or Android SDK build-tools are installed."
    exit 1
fi

echo "=== [1/5] Compiling Native C++ Engine Library ==="
mkdir -p android/app/src/main/libs/arm64-v8a
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
cd ..

echo "=== [2/5] Compiling Android Resource Manifest ==="
mkdir -p android/build/compiled_res android/build/apk
$AAPT2_BIN compile --dir android/app/src/main/res -o android/build/compiled_res/ 2>/dev/null || true
$AAPT2_BIN link -o android/build/hyperion_unaligned.apk \
    -I $PREFIX/share/aapt/android.jar \
    --manifest android/app/src/main/AndroidManifest.xml \
    --java android/build/src \
    --auto-add-overlay

echo "=== [3/5] Compiling Java Entry Point ==="
mkdir -p android/build/obj
ecj -d android/build/obj \
    -cp $PREFIX/share/aapt/android.jar \
    android/app/src/main/java/com/hyperion/engine/MainActivity.java

echo "=== [4/5] Packaging Dex & Native Library ==="
dx --dex --output=android/build/classes.dex android/build/obj
cd android/build
$AAPT2_BIN add hyperion_unaligned.apk classes.dex
cd ../..

# Copy compiled native shared library into APK structure
mkdir -p android/build/lib/arm64-v8a
cp build/hyperion_x android/build/lib/arm64-v8a/libhyperion-engine.so
cd android/build
$AAPT2_BIN add hyperion_unaligned.apk lib/arm64-v8a/libhyperion-engine.so
cd ../..

echo "=== [5/5] Signing APK ==="
if [ ! -f hyperion.keystore ]; then
    keytool -genkey -v -keystore hyperion.keystore -alias hyperion -keyalg RSA -keysize 2048 -validity 10000 -storepass password -keypass password -dname "CN=Hyperion, OU=Dev, O=Engine, L=Mobile, S=Dev, C=US"
fi

apksigner sign --ks hyperion.keystore --ks-pass pass:password --out HYPERION-X.apk android/build/hyperion_unaligned.apk

echo "SUCCESS: HYPERION-X.apk built successfully!"
ls -lh HYPERION-X.apk
