#!/usr/bin/env sh

DEST=./.build/debug
SWIFTFILE=../${SWIFTFILE}
/bin/bash -c "source Scripts/build-swift.sh"
cp -r templates $DEST
cd .build/debug && zip Hexaville.zip Hexaville ./*.so ./*.so.* -r templates
