#!/bin/sh

#download the source
LUASRC_NAME=LuaJIT-2.0.2.tar.gz
LUASRC_URL=http://luajit.org/download/LuaJIT-2.0.2.tar.gz
if [ -e $LUASRC_NAME ] 
then
	echo 'file exist'
else
	curl $LUASRC_URL -o $LUASRC_NAME
fi
tar -zxvf $LUASRC_NAME

#prepare the environment
LUAJIT=LuaJIT-2.0.2
ISDK=`xcode-select -print-path`/Platforms/iPhoneOS.platform/Developer
ISDKVER=iPhoneOS6.1.sdk
ISDKP=$ISDK/usr/bin/
CC=/Applications/Xcode.app/Contents/Developer/usr/llvm-gcc-4.2/bin/llvm-gcc-4.2

FRAMEWORK_NAME=LuaJIT
FRAMEWORK_DIR=$FRAMEWORK_NAME.framework

cd $LUAJIT

#clean
rm -rf iOS
mkdir iOS

#make for iP3/4
make HOST_CC="$CC -m32 -arch i386" CROSS=$ISDKP TARGET_FLAGS="-arch armv7 -isysroot $ISDK/SDKs/$ISDKVER" TARGET=arm TARGET_SYS=iOS clean all
cp -p src/libluajit.a iOS/libluajit-armv7.a

#make for iP5
make HOST_CC="$CC -m32 -arch i386" CROSS=$ISDKP TARGET_FLAGS="-arch armv7s -isysroot $ISDK/SDKs/$ISDKVER" TARGET=arm TARGET_SYS=iOS clean all
cp -p src/libluajit.a iOS/libluajit-armv7s.a

#make for Simulator
make CC="$CC -m32" clean all
cp -p src/libluajit.a iOS/libluajit-i386.a

#combine files
make clean
mkdir $FRAMEWORK_DIR
mkdir $FRAMEWORK_DIR/Headers
lipo -create iOS/libluajit-*.a -output ./$FRAMEWORK_DIR/LuaJIT
rm iOS/libluajit-*.a

#copy headers
cp src/luajit.h src/luaconf.h src/lua.h src/lua.hpp src/lauxlib.h src/lualib.h ./$FRAMEWORK_DIR/Headers
mv $FRAMEWORK_DIR/Headers/luajit.h $FRAMEWORK_DIR/Headers/lua_jit.h

# Fix-up header files to use standard framework-style include paths
FRAMEWORK_HEADER=$FRAMEWORK_DIR/Headers/LuaJIT.h
if [ -e $FRAMEWORK_HEADER ]
then
	echo 'FRAMEWORK HEADER EXIST'
	rm $FRAMEWORK_HEADER
fi

cd $FRAMEWORK_DIR/Headers/
for FILE in *.h
do
	#sed -i "" "s:#include \"\(.*\)\":#include <$FRAMEWORK_NAME/\1>:" "$FILE"
	echo "#include <$FRAMEWORK_NAME/$FILE>" >> LuaJIT.h
done
cd ../../
