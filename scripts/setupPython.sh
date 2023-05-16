#!/bin/bash
## Description: Setup Python local virtual env
# Install the Xcode command line tools's SDK headers to the legacy (pre-Mojave)
# location so Homebrew and other package management tools will find them in the
# expected location. For more info, see:
# https://silvae86.github.io/sysadmin/mac/osx/mojave/beta/libxml2/2018/07/05/fixing-missing-headers-for-homebrew-in-mac-osx-mojave/
if sw_vers -productVersion | grep 10.14. > /dev/null; then
  echo "Detected OS Mojave. Checking for Xcode command line tools headers in legacy location..."
  if pkgutil --pkgs=com\.apple\.pkg\.macOS_SDK_headers_for_macOS_10\.14 > /dev/null; then
    echo "Xcode command line tools headers already installed to the legacy location."
  else
    echo "Installing Xcode command line tools headers to the legacy location..."
    cp /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg ~/Desktop
    installer -pkg /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg -target /
  fi
else
  echo "OS version other than Mojave detected. Not checking for Xcode command line tools headers in legacy location."
fi
# Download / Install Virtualenv (as this might not be available on all
# environments)
echo "Virtual environment for Python $VIRTUAL_ENV_VERSION not detected. Downloading..."
pip install virtualenv
echo "Starting virtual environment for Python $VIRTUAL_ENV_VERSION..."
virtualenv android_build
# Activate and install requirements
source android_build/bin/activate
PYTHON_DEPS_FILE=./scripts/py_requirements.txt
echo "Installing python dependencies enumerated in $PYTHON_DEPS_FILE..."
pip install -r $PYTHON_DEPS_FILE -vvv
# Deactivate environment after installation
echo "Exiting virtual environment for Python $VIRTUAL_ENV_VERSION..."
deactivate
# Clean up downloaded temp virtualenv files
echo "Cleaning up virtual environment for Python $VIRTUAL_ENV_VERSION..."
rm -rf ./virtualenv-$VIRTUAL_ENV_VERSION/ ./virtualenv-$VIRTUAL_ENV_VERSION.tar.gz
