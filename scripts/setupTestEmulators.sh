#!/usr/bin/env sh

#TODO: These should be parameterized for future flexability
AVD_NAME="Nexus_5X_API_29"
AVD_PACKAGE="system-images;android-29;google_apis_playstore;x86"
AVD_DEVICE="Nexus 5X"
AVD_PORT="5560"  # Port # to help distinguish if Emulator is Running of this type (must be between 5555-5586)

echo "Setup and Launching Android Emulator for Testing"
pushd ./
cd $ANDROID_HOME/tools/bin

echo "Checking if Emulator Exists"
./avdmanager list avd | grep "Name: $AVD_NAME" > /dev/null
if [[ $? != 0 ]]
then
	echo "Creating AVD Emulator"
	./avdmanager -v create avd --name "$AVD_NAME" -k "$AVD_PACKAGE" --device "$AVD_DEVICE"
fi

echo "Checking if Emulator is running"
adb devices -l | grep "$AVD_PORT" > /dev/null

# To Kill the Emulator, we can run this command:
#adb -s emulator-$AVD_PORT emu kill

if [[ $? != 0 ]]
then
	echo "Launching Emulator"
	cd ../../emulator
	# \n for weird hack because you have to press enter..
	echo "\n" | ./emulator @$AVD_NAME -port $AVD_PORT -no-boot-anim &
fi

echo "Android Emulator Setup/Running complete"

popd
