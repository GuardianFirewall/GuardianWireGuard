#!/bin/bash

# clear previous build folder if it exist
rm -rf build

# remove the old copy of the xcframework if it already exists
rm -rf GRDWireGuardKit.xcframework

# remove the old copy of the xcframework zip if it already exists
rm -rf GRDWireGuardKit.xcframework.zip

xcodebuild -sdk iphonesimulator -target GRDWireGuardKitiOS
xcodebuild -sdk iphoneos -target GRDWireGuardKitiOS
xcodebuild -sdk macosx -target GRDWireGuardKitmacOS

pwd=$(pwd)
lipo=$(which lipo)

# change to the release-iphoneos folder to get the name of the framework (this is to make this script more universal)
pushd build/Release-iphoneos || exit

# find the name of the framework, in our case 'GRDWireGuardKit'
for i in $(find ./* -name "*.framework"); do
    name=${i%\.*}
    echo "$name"
done

# pop back to the GRDWireGuardKit folder
popd || exit

# create variables for the path to each respective framework
ios_fwpath=$pwd/build/Release-iphoneos/$name.framework
sim_fwpath=$pwd/build/Release-iphonesimulator/$name.framework
mac_path=$pwd/build/Release/$name.framework

# create the xcframework
xcodebuild -create-xcframework -framework "$ios_fwpath" -framework "$sim_fwpath" -framework "$mac_path" -output "$name".xcframework

printf "\n\n"
printf "Proccesing SwiftPM artifacts\n"

printf "Creating .zip archive...\n"
# create .zip of the framework for SwiftPM
ditto -c -k --sequesterRsrc --keepParent "./GRDWireGuardKit.xcframework" "./GRDWireGuardKit.xcframework.zip"

printf "\n"
printf "SwiftPM .zip checksum:\n"
# get hash checksum for SwiftPM
swift package compute-checksum "./GRDWireGuardKit.xcframework.zip"

open -R "$name".xcframework.zip
