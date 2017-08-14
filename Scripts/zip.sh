#!/usr/bin/env sh

DEST=./.build/release
SWIFTFILE=../${SWIFTFILE}
/bin/bash -c "source Scripts/build-swift.sh"
cp -r templates $DEST
cp -r Scripts $DEST
cd .build/debug && zip Hexaville.zip Hexaville ./*.so ./*.so.* -r templates -r Scripts
