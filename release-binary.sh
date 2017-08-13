#!/usr/bin/env sh

if [ $# -ne 1 ]; then
  echo "Please specify destination<directory> for binaries as a first argument"
  exit 1
fi

MAC_DIST=bin/latest/mac
LINUX_DIST=bin/latest/linux

mkdir -p $1/$MAC_DIST
mkdir -p $1/$LINUX_DIST

SHARED_DIR=`pwd`/__docker_shared
docker build --no-cache -t hexaville .
docker run -v ${SHARED_DIR}:/Hexaville/.build hexaville
mv ${SHARED_DIR}/debug/Hexaville.zip $1/$LINUX_DIST

swift build -c release
cp -r templates .build/release
cp -r Scripts .build/release
cd .build/release
zip $1/$MAC_DIST/Hexaville.zip Hexaville -r templates -r Scripts
