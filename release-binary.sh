#!/usr/bin/env sh

SHARED_DIR=`pwd`/__docker_shared
docker build -t hexaville .
docker run -v ${SHARED_DIR}:/Hexaville/.build hexaville
mv ${SHARED_DIR}/debug/Hexaville.zip ./bin/latest/linux

swift build
cp -r templates .build/debug
cd .build/debug
zip ../../bin/latest/mac/Hexaville.zip Hexaville -r templates
