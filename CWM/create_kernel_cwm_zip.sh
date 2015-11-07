#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -z $1 ]; then
  echo "Give kernel name plz. Date will be appended automatically"
  exit 1
fi
PREFIX=$1

export PLATFORM="AOSP"
export KERNELDIR=`readlink -f .`
export INITRAMFS_DEST=$KERNELDIR/kernel/usr/initramfs
export PACKAGEDIR=$DIR/workdir
export INITRAMFS_BRANCH=aosp-5.1
export INITRAMFS_SOURCE=$(readlink -f $DIR/../../Ramdisk)
#export RD_CMDLINE="androidboot.hardware=qcom user_debug=31 zcache msm_rtb.filter=0x3F ehci-hcd.park=3 androidboot.bootdevice=msm_sdcc.1"
export RD_CMDLINE="androidboot.hardware=qcom user_debug=31 zcache msm_rtb.filter=0x3F ehci-hcd.park=3"

## check zImage existence
if [ ! -e ${KERNELDIR}/arch/arm/boot/zImage ]; then
  echo "No zImage found: $KERNELDIR/arch/arm/boot/zImage"
  exit 1
fi

## version
VER=${PREFIX}_$(date -r $KERNELDIR/arch/arm/boot/zImage +%Y%m%d_%H%M%S)
echo "**** Version: $VER"

## prepare workdir
pushd ${DIR}
if [ -e workdir ]; then
    rm -rf workdir
fi
mkdir -p ${PACKAGEDIR}/system/lib/modules
popd

## prepare initramfs dir
if [ -e ${INITRAMFS_DEST} ]; then
  rm -rf ${INITRAMFS_DEST}
fi
mkdir -p ${INITRAMFS_DEST}

## check ramdisk source
if [ ! -e ${INITRAMFS_SOURCE} ]; then
  echo "Cannot find Ramdisk dir: $INITRAMFS_SOURCE"
  exit 1
fi

## checkout correct branch
pushd ${INITRAMFS_SOURCE}
git checkout $INITRAMFS_BRANCH
if [ ! $? -eq 0 ]; then
  echo "Cannot checkout branch $INITRAMFS_BRANCH in $INITRAMFS_SOURCE"
  exit 1
fi
popd
## copy initramfs src to dst
cp -R ${INITRAMFS_SOURCE}/* ${INITRAMFS_DEST}

echo "**** chmod initramfs dir"
chmod -R g-w ${INITRAMFS_DEST}/*
rm $(find $INITRAMFS_DEST -name EMPTY_DIRECTORY -print)
rm -rf $(find $INITRAMFS_DEST -name .git -print)

echo "**** Copy modules to Package"
cp -a $(find . -name *.ko -print |grep -v initramfs) ${PACKAGEDIR}/system/lib/modules/

echo "**** Copy zImage to Package"
cp arch/arm/boot/zImage ${PACKAGEDIR}/zImage

echo "**** Make boot.img"
$DIR/tools/mkbootfs ${INITRAMFS_DEST} | gzip > ${PACKAGEDIR}/ramdisk.gz
$DIR/tools/mkbootimg --cmdline "$RD_CMDLINE" --kernel ${PACKAGEDIR}/zImage --ramdisk ${PACKAGEDIR}/ramdisk.gz --base 0x80200000 --pagesize 2048 --ramdisk_offset 0x02000000 --output ${PACKAGEDIR}/boot.img 

cd ${PACKAGEDIR}

cp -R ${DIR}/meta_kernel_${INITRAMFS_BRANCH} META-INF
#cp -R ../kernel .

rm ramdisk.gz
rm zImage
rm ${KERNELDIR}/${VER}.zip*
zip -r ${KERNELDIR}/${VER}.zip .
cd ${KERNELDIR}
md5sum ${VER}.zip > ${VER}.zip.md5sum 


