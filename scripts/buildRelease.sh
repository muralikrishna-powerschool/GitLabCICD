#!/bin/sh

# Clean Project and Build Folders
./gradlew clean
find . -type d -name "build" -exec rm -rf {} \;

set -e
# Bundle Release
./gradlew bundleRelease

# Assemble Release
./gradlew assembleRelease

# Copy Release Data into Release Folder
rm -rf ./Release
mkdir Release
find ./app/build/outputs/bundle/release -type f -name "app-release.aab" -exec cp {} ./Release \;
find ./app/build/outputs/apk -type f -name "app-release.apk" -exec cp {} ./Release \;
cp ./app/build/outputs/mapping/release/mapping.txt ./Release/mapping.txt
