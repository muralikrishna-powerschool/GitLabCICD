#!/bin/sh

# Clean Project and Build Folders
./gradlew clean
find . -type d -name "build" -exec rm -rf {} \;

set -e
# Bundle Release
./gradlew bundleDebug

# Assemble Release
./gradlew assembleDebug

# Copy Release Data into Release Folder
rm -rf ./Debug
mkdir Debug
find ./app/build/outputs/bundle/debug -type f -name "app-debug.aab" -exec cp {} ./Debug \;
find ./app/build/outputs/apk -type f -name "app-debug.apk" -exec cp {} ./Debug \;
cp ./app/build/outputs/mapping/debug/mapping.txt ./Debug/mapping.txt
