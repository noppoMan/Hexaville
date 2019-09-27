#!/usr/bin/env sh

set -e

SWIFTFILE=../${SWIFTFILE}
DEST=.build/${BUILD_CONFIGURATION}
swift package update
swift build -c ${BUILD_CONFIGURATION}
cp -r /${SWIFTFILE}/usr/lib/swift/linux/*.so $DEST
mv $DEST/libicudataswift.so $DEST/libicudataswift.so.61
mv $DEST/libicui18nswift.so $DEST/libicui18nswift.so.61
mv $DEST/libicuucswift.so $DEST/libicuucswift.so.61
cp /usr/lib/x86_64-linux-gnu/libicudata.so $DEST/libicudata.so.52
cp /usr/lib/x86_64-linux-gnu/libicui18n.so $DEST/libicui18n.so.52
cp /usr/lib/x86_64-linux-gnu/libicuuc.so $DEST/libicuuc.so.52
cp /usr/lib/x86_64-linux-gnu/libbsd.so $DEST/libbsd.so.0
cp /lib/x86_64-linux-gnu/libssl.so.1.0.0 $DEST/libssl.so.1.0.0
cp /lib/x86_64-linux-gnu/libcrypto.so.1.0.0 $DEST/libcrypto.so.1.0.0
cp -r templates $DEST
cp -r Scripts $DEST
echo "$PUBLISH_VERSION" > $DEST/.hexaville-version
cd $DEST
zip Hexaville.zip hexaville .hexaville-version ./*.so ./*.so.* -r templates -r Scripts
