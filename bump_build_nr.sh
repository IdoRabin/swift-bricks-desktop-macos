#!/bin/sh
dir=$PWD
${PROJECT_DIR}
#"usr/syncme/xcode/bricks/"
pushd ~/xcode/bricks/
xcrun agvtool next-version -all
#ver=`xcrun agvtool what-version -terse`
#say "build $ver" -v Alex
#echo "build version now: $ver"
popd
#cd $dir
