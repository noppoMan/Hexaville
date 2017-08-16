#!/usr/bin/env sh

set -e

DEST=${DEST}/${BUILD_CONFIGURATION}
swift package update
swift build -c ${BUILD_CONFIGURATION}
cp -r /${SWIFTFILE}/usr/lib/swift/linux/*.so $DEST
cp /usr/lib/x86_64-linux-gnu/libicudata.so $DEST/libicudata.so.52
cp /usr/lib/x86_64-linux-gnu/libicui18n.so $DEST/libicui18n.so.52
cp /usr/lib/x86_64-linux-gnu/libicuuc.so $DEST/libicuuc.so.52
cp /usr/lib/x86_64-linux-gnu/libbsd.so $DEST/libbsd.so.0

UNAME=`uname`;
if [[ $UNAME == "Linux" ]]; then
  $DEST/$EXECUTABLE_NAME gen-routing-manif $DEST
  id -u $VOLUME_USER &>/dev/null || useradd -ms /bin/bash $VOLUME_USER
  chown -R $VOLUME_USER:$VOLUME_GROUP $DEST
fi
