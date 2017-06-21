#!/usr/bin/env sh

cd $2
zip $1 $3 byline.js index.js ./*.so ./*.so.*
