#!/bin/bash

CUR_PATH=$(cd "$(dirname $0)";pwd)
SRC_PATH=$CUR_PATH/base
SDK_PATH=$(realpath $CUR_PATH/..)
IFS=$'\n'

echo "SRC_PATH: $SRC_PATH"
echo "SDK_PATH: $SDK_PATH" 

# check SDK path
if [ -e $SRC_PATH ]
then
    for file in `ls $SRC_PATH`
    do
        if [ -d $SRC_PATH"/"$file ]
        then
            if [ ! -d $SDK_PATH"/"$file ]
            then
                echo "error: not a SDK path!"
                exit
            fi
        fi
    done
else
    echo "error: not a source path!"
    exit
fi

cp -rfv $SRC_PATH/* $SDK_PATH/

if [ -d "$SDK_PATH/buildroot/board/rockchip/rk3506/picocalc-overlay" ]
then
    rm -rf $SDK_PATH/buildroot/board/rockchip/rk3506/picocalc-overlay
fi
ln -sr $SRC_PATH/buildroot/board/rockchip/rk3506/picocalc-overlay $SDK_PATH/buildroot/board/rockchip/rk3506/picocalc-overlay

# Fix issue with running build in docker
sed -i 's/btrfs/btrfs | overlay/' $SDK_PATH/device/rockchip/common/scripts/check-sdk.sh