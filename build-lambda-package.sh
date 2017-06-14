#!/usr/bin/env sh

cd $2
zip $1 $3 ./*.so ./*.so.*
