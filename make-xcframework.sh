#!/bin/bash

set -e
set -o pipefail
set -u

name=Yams
project=$name.xcodeproj
output=build/$name.xcframework
for sdk in watchos watchsimulator iphoneos iphonesimulator appletvos appletvsimulator macosx; do
  xcodebuild \
    -project $project \
    -scheme $name \
    archive \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    -archivePath tmp/xcframework/build/$name-$sdk.xcarchive \
    -sdk $sdk
done

xcodebuild -create-xcframework \
  -framework tmp/xcframework/build/$name-watchos.xcarchive/Products/Library/Frameworks/$name.framework \
  -framework tmp/xcframework/build/$name-watchsimulator.xcarchive/Products/Library/Frameworks/$name.framework \
  -framework tmp/xcframework/build/$name-iphoneos.xcarchive/Products/Library/Frameworks/$name.framework \
  -framework tmp/xcframework/build/$name-iphonesimulator.xcarchive/Products/Library/Frameworks/$name.framework \
  -framework tmp/xcframework/build/$name-appletvos.xcarchive/Products/Library/Frameworks/$name.framework \
  -framework tmp/xcframework/build/$name-appletvsimulator.xcarchive/Products/Library/Frameworks/$name.framework \
  -framework tmp/xcframework/build/$name-macosx.xcarchive/Products/Library/Frameworks/$name.framework \
  -output $output
