#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CURDIR=$(pwd)

ZIPNAME=full_jactivelte-ota-eng.$(whoami).zip
ZIPPATH=$OUT/$ZIPNAME

ANDROID_VER=$(cat ${ANDROID_BUILD_TOP}/.repo/manifest.xml | grep "<default revision=\"refs/tags/android-" | cut -d - -f 2)
ANDROID_VERLEN=$(echo $ANDROID_VER | wc -c)
ANDROID_VERLEN=$(expr ${ANDROID_VERLEN} - 2)
ANDROID_VER=$(echo ${ANDROID_VER} | cut -c "-${ANDROID_VERLEN}")
echo Android version: ${ANDROID_VER}

if [ -z $1 ]; then
    echo "No version given (want for example 0.5!), exiting..."
    exit 1
fi

if [ ! -e $ZIPPATH ]; then
    if [ -e $OUT/full_jactivelte-ota-eng.spegelius.zip ]; then
        ZIPNAME=full_jactivelte-ota-eng.spegelius.zip
        ZIPPATH=$OUT/$ZIPNAME
    else
        echo "No zip $ZIPPATH found, exiting..."
        exit 2
    fi
fi

VER="$1"
METADIR=meta_${ANDROID_VER}

if [ "$2" == "--dualboot" ]; then
    echo "**"
    echo Dualboot enabled
    echo "**"
    DUALBOOT=${DIR}/../../DualBootPatcher-8.0.0-release/
    VER="${VER}_dualboot"
fi

TARGETZIP="AOSP_${ANDROID_VER}_I9295_spegelius_v${VER}.zip"

cd ${DIR}
if [ -e workdir ]; then
    rm -rf workdir
fi
mkdir workdir
cd workdir
unzip -q $ZIPPATH
WORKDIR=$(pwd)

MOUNTS=${DIR}/${METADIR}/updater-script_template_mounts
UNMOUNTS=${DIR}/${METADIR}/updater-script_template_unmounts

if [ ! -z ${DUALBOOT} ]; then
    if [ ! -d ${DUALBOOT} ]; then
        echo "Dualboot directory not found, exiting..."
        exit 3
    fi
	cp ${DUALBOOT}/patches/dualboot.sh ${WORKDIR}
    # patch bootimage
    ${DUALBOOT}/patch-file.sh ${WORKDIR}/boot.img -d jflte
    rm ${WORKDIR}/boot.img
    mv ${WORKDIR}/boot_dual.img ${WORKDIR}/boot.img
    cp ${DIR}/dualboot.sh ${WORKDIR}

    MOUNTS=${DIR}/meta_dualboot/updater-script_template_mounts
    UNMOUNTS=${DIR}/meta_dualboot/updater-script_template_unmounts
fi

cp -rf ${DIR}/system/* ${WORKDIR}/system/

# zip META_INF
echo "**"
echo Adding META-INF from ${DIR}/${METADIR}
echo "**"
mkdir -p ${DIR}/${METADIR}/META-INF/com/google/android/

AVERSTRING="${ANDROID_VER} for GT-I9295"
COUNT=$(expr 25 - $(echo $AVERSTRING | wc -c))
for i in $(eval echo "{1..$COUNT}"); do
    AVERSTRING="${AVERSTRING} "
done

VERSTRING="${VER}"
COUNT=$(expr 40 - $(echo $VERSTRING | wc -c))
for i in $(eval echo "{1..$COUNT}"); do
    VERSTRING="${VERSTRING} "
done
echo $AVERSTRING
echo $VERSTRING

cat ${DIR}/${METADIR}/updater-script_template_start | sed "s/ANDROIDVERHERE/v${AVERSTRING}*\");/" > ${DIR}/${METADIR}/_temp
cat ${DIR}/${METADIR}/_temp | sed "s/VERSIONSTRINGHERE/ui_print\(\"\* v${VERSTRING}*\");/" > ${DIR}/${METADIR}/META-INF/com/google/android/updater-script
rm ${DIR}/${METADIR}/_temp
cat ${MOUNTS} >> ${DIR}/${METADIR}/META-INF/com/google/android/updater-script
cat ${DIR}/${METADIR}/updater-script_template_middle >> ${DIR}/${METADIR}/META-INF/com/google/android/updater-script
cat ${UNMOUNTS} >> ${DIR}/${METADIR}/META-INF/com/google/android/updater-script
cat ${DIR}/${METADIR}/updater-script_template_end >> ${DIR}/${METADIR}/META-INF/com/google/android/updater-script

cp -rf ${DIR}/${METADIR}/META-INF/* ${WORKDIR}/META-INF/

cd ${WORKDIR}

if [ -e ${CURDIR}/${TARGETZIP} ]; then
    rm ${CURDIR}/${TARGETZIP}
fi

zip -qr ${CURDIR}/${TARGETZIP} *
cd ${CURDIR}
md5sum ${TARGETZIP} > ${TARGETZIP}.md5sum

