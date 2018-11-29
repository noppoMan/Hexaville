#!/usr/bin/env bash

set -e

VERSION="4.2"

# Determine OS
UNAME=`uname`;
if [[ $UNAME == "Darwin" ]];
then
    OS="macos";
else
    if [[ $UNAME == "Linux" ]];
    then
        OS="ubuntu1604";
    fi
fi

if [[ $OS != "macos" ]];
then
    sudo apt-get update
    sudo apt-get install -y clang libicu-dev uuid-dev
    SWIFTFILE="swift-$VERSION-RELEASE-ubuntu16.04";
    wget https://swift.org/builds/swift-$VERSION-release/$OS/swift-$VERSION-RELEASE/$SWIFTFILE.tar.gz
    tar -zxf $SWIFTFILE.tar.gz
    export PATH=$PWD/$SWIFTFILE/usr/bin:"${PATH}"
fi
