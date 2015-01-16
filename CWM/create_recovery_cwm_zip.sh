#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CURDIR=$(pwd)

echo "Creating recovery CWM installer"

if [ -z $1 ]; then
    echo "No recovery.img path given, exit"
    exit 1
fi

cp "$1" /tmp/recovery.img_temp

if [ -z $2 ]; then
    echo "No version given (want for example 0.5!)"
    exit 1
else
    VER="$2"
fi
VERSION="$2"_$(date -r ${1} +%Y%m%d_%H%M%S)

TARGETZIP=$VERSION".zip"

cd ${DIR}
if [ -e workdir ]; then
    rm -rf workdir
fi
mkdir workdir
cd workdir
WORKDIR=$(pwd)

cp -r ${DIR}/meta_recovery/META-INF .
sed -i "s/NAME/${VERSION}/" META-INF/com/google/android/updater-script
mv /tmp/recovery.img_temp recovery.img


cd ${WORKDIR}

if [ -e ${CURDIR}/${TARGETZIP} ]; then
    rm ${CURDIR}/${TARGETZIP}
fi

zip -qr ${CURDIR}/${TARGETZIP} *
cd ${CURDIR}
md5sum ${TARGETZIP} > ${TARGETZIP}.md5sum

