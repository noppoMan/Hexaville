#!/usr/bin/env sh

set -e

if [ $# -ne 1 ]; then
  echo "Please specify destination<directory> for binaries as a first argument"
  exit 1
fi

SWIFT_BUILD_CONFIGURATION=release
MAC_DIST=bin/latest/mac
LINUX_DIST=bin/latest/linux

mkdir -p $1/$MAC_DIST
mkdir -p $1/$LINUX_DIST

SHARED_DIR=`pwd`/__docker_shared
docker build --no-cache -t hexaville .
docker run -v ${SHARED_DIR}:/Hexaville/.build hexaville
mv ${SHARED_DIR}/${SWIFT_BUILD_CONFIGURATION}/Hexaville.zip $1/$LINUX_DIST

swift build -c ${SWIFT_BUILD_CONFIGURATION}
cp -r templates .build/${SWIFT_BUILD_CONFIGURATION}
cp -r Scripts .build/${SWIFT_BUILD_CONFIGURATION}
cd .build/${SWIFT_BUILD_CONFIGURATION}
zip $1/$MAC_DIST/Hexaville.zip hexaville -r templates -r Scripts
