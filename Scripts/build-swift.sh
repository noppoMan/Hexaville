#!/usr/bin/env sh

set -e

DEST=${DEST}/${BUILD_CONFIGURATION}
swift package update
swift build -c ${BUILD_CONFIGURATION}

# swift libraries
rm $DEST/libicudataswift.so.61 $DEST/libicui18nswift.so.61 $DEST/libicuucswift.so.61
cp -rL /${SWIFTFILE}/usr/lib/swift/linux/*.so $DEST
mv $DEST/libicudataswift.so $DEST/libicudataswift.so.61
mv $DEST/libicui18nswift.so $DEST/libicui18nswift.so.61
mv $DEST/libicuucswift.so $DEST/libicuucswift.so.61

# other sysytem libraries
cp /usr/lib/x86_64-linux-gnu/libicui18n.so $DEST/libicui18n.so.52
cp /usr/lib/x86_64-linux-gnu/libicuuc.so $DEST/libicuuc.so.52
cp /usr/lib/x86_64-linux-gnu/libbsd.so $DEST/libbsd.so.0
cp /lib/x86_64-linux-gnu/libssl.so.1.0.0 $DEST/libssl.so.1.0.0
cp /lib/x86_64-linux-gnu/libcrypto.so.1.0.0 $DEST/libcrypto.so.1.0.0

if [ -z "${VOLUME_USER}" ] && [ -z "${VOLUME_GROUP}" ]; then
    echo "swift build is finished."
else
    id -u $VOLUME_USER &>/dev/null || useradd -ms /bin/bash $VOLUME_USER
    chown -R $VOLUME_USER:$VOLUME_GROUP $DEST
    echo "swift build is finished."
fi
