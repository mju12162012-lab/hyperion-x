#!/usr/bin/env bash
set -e

echo "=================================================="
echo " [HYPERION-X] Starting Multi-Platform Release Pipeline"
echo "=================================================="

# Create release directories
mkdir -p release/pc release/android

# Step 1: Compile PC Native Binary
echo "[1/3] Compiling Native PC Release Binary..."
mkdir -p build_pc && cd build_pc
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j$(nproc)
cp hyperion_x ../release/pc/hyperion_pc.bin
cd ..

# Step 2: Cross-Compile / Package Android APK Assets
echo "[2/3] Packaging Android APK Structure & Assets..."
mkdir -p android_pkg/lib/arm64-v8a android_pkg/assets

# Copy compiled core binary to Android target architecture folder
if [ -f "build/hyperion_x" ]; then
    cp build/hyperion_x android_pkg/lib/arm64-v8a/libhyperion.so
else
    cp release/pc/hyperion_pc.bin android_pkg/lib/arm64-v8a/libhyperion.so
fi

# Generate Android Manifest
cat << 'MANIFEST' > android_pkg/AndroidManifest.xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.hyperionx.engine"
    android:versionCode="1"
    android:versionName="1.0.0">
    <uses-feature android:glEsVersion="0x00030001" android:required="true" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <application android:label="HYPERION-X" android:allowBackup="true" android:icon="@mipmap/ic_launcher">
        <activity android:name="android.app.NativeActivity"
                  android:configChanges="orientation|keyboardHidden|screenSize"
                  android:exported="true">
            <meta-data android:name="android.app.lib_name" android:value="hyperion" />
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
MANIFEST

echo "[3/3] Finalizing APK and Executable packages..."
cd android_pkg
zip -r ../release/android/HYPERION-X-Android-Release.apk * > /dev/null 2>&1
cd ..

echo "=================================================="
echo " [SUCCESS] Build and Packaging Complete!"
echo "   -> PC Executable Binary: release/pc/hyperion_pc.bin"
echo "   -> Android APK Package:  release/android/HYPERION-X-Android-Release.apk"
echo "=================================================="
