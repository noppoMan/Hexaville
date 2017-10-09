#!/usr/bin/env sh

set -e

SWIFTFILE=../${SWIFTFILE}
DEST=.build/release
swift package update
swift build -c ${BUILD_CONFIGURATION}
cp -r /${SWIFTFILE}/usr/lib/swift/linux/*.so $DEST
cp /usr/lib/x86_64-linux-gnu/libicudata.so $DEST/libicudata.so.52
cp /usr/lib/x86_64-linux-gnu/libicui18n.so $DEST/libicui18n.so.52
cp /usr/lib/x86_64-linux-gnu/libicuuc.so $DEST/libicuuc.so.52
cp /usr/lib/x86_64-linux-gnu/libbsd.so $DEST/libbsd.so.0
cp -r templates $DEST
cp -r Scripts $DEST
cd $DEST
zip Hexaville.zip hexaville ./*.so ./*.so.* -r templates -r Scripts
