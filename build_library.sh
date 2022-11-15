#!/bin/bash

# # #
# Note from CJ 2022-05-20
# As of right now building this on Apple Silicon and running it in the iPhone Simulator is unsupported
# due to missing symbols in the cgo runtime while cross compiling WireGuard itself which is Go based.
# Building and using this library on x86_64 based systems should be no problem.
# This is still somewhat unknown... building straight to an iOS device or for any
# Mac architecture is no problem though
#
# For use on iOS: the xcodebuild command for the iPhone Simulator will fail
# but the other targets will build and be exported just fine. Navigate into the './build'
# folder to pickout the slice for the architecture that you require
# # #


xcodebuild -sdk iphonesimulator -target GRDWireGuardKitiOS
xcodebuild -sdk iphoneos -target GRDWireGuardKitiOS
xcodebuild -sdk macosx -target GRDWireGuardKitmacOS

pwd=$(pwd)
lipo=$(which lipo)
cd "./build/Release-iphoneos"

# Note from CJ 2022-05-20
# Still not sure if all the WireGuard related .a need to be excluded explicitly or not.
# I believe that they are not required
for i in $(find * -type f -name '*.a' ! -name 'libwg-go*' -not -path '*/wireguard-go-bridge/*'); do
	name=${i%\.*}
	echo "$name"
done

outputfile=$name.a
uniname=$outputfile.uni
fwpath=$pwd/build/Release-iphoneos/$name.a
incpath=$pwd/build/Release-iphoneos/include
fullpath=$pwd/build/Release-iphoneos/$uniname

lipocmd="$lipo -create $outputfile ../Release-iphonesimulator/$outputfile -output $uniname"
echo "$lipocmd"
$lipocmd
echo "$fullpath"
chmod +x "$uniname"

if [ -f "$fullpath" ]; then
	rm "$outputfile"
	mv "$uniname" "$outputfile"
	mv "$fwpath" ../..

	if [ -d "$incpath" ]; then
		echo "Found include path: $incpath"
		cp -r "$incpath" ../..
	fi

	echo "Done, macOS library is in the build/Release folder, the others will be in the root folder"
	open "$pwd"
else
	echo "The file does not exist";
fi
