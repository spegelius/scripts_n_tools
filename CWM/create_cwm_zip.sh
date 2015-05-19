#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CURDIR=$(pwd)


function find_ota_zip() {

    pushd $OUT

	ZIPNAME=$(ls -lt *-ota-*.zip | head -n 1 | awk '{ print $9}')
	if [ "${ZIPNAME}" == "" ]; then
		echo "No ota zip found, exiting..."
		popd
		exit 1
	fi

    popd
}

function build_type() {
	ANDROID_VER=$(cat ${ANDROID_BUILD_TOP}/.repo/manifest.xml | grep "<default revision=\"refs/tags/android-" | cut -d - -f 2)
	if [ "$ANDROID_VER" != "" ]; then
	    TYPE="AOSP"
	else
	    ANDROID_VER=$(cat ${ANDROID_BUILD_TOP}/.repo/manifest.xml | grep "<default revision=\"refs/heads/cm-" | cut -d - -f 2)

    	if [ "$ANDROID_VER" != "" ]; then
	        TYPE="CM"
	    else
            echo "Unknown rom in $OUT"
            exit 1
	    fi
	fi
    ANDROID_VERLEN=$(echo $ANDROID_VER | wc -c)
    ANDROID_VERLEN=$(expr ${ANDROID_VERLEN} - 2)
    ANDROID_VER=$(echo ${ANDROID_VER} | cut -c "-${ANDROID_VERLEN}")
    
    METADIR=meta_${TYPE}_${ANDROID_VER}

    if [ "${TYPE}" == "CM" ]; then
        if [ "${ANDROID_VER}" == "12.0" ]; then
            ANDROID_VER="12"
        elif [ "${ANDROID_VER}" == "11.0" ]; then
            ANDROID_VER="11"
        fi
    fi
}

function do_help() {
    echo "Create CWM flashable zip based on current build environment values."
    echo "Supports AOSP 4.3 and 4.4, CM11 and CM12 otapackage builds"
    echo
    echo "Options:"
    echo "-h, --help              This help"
    echo "-d, --dualboot          Dualboot enabled updater scripts"
    echo "-y, --dynfs             Dynamic filesystem updater script support (ext4/f2fs)"
    echo "-v=VER, --version=VER   ROM version string (if not used, date is used)"
    echo "-e=VER, --extraver=VER  Extra string to be appended to version string"
    exit 0
}

build_type
find_ota_zip


ZIPPATH=$OUT/$ZIPNAME
echo "Using OTA zip: ${ZIPPATH}"


echo Android version: ${ANDROID_VER}, type: ${TYPE}


for i in "$@"
do
case $i in
    -v=*|--version=*)
    VER="${i#*=}"
    shift
    ;;
    -d|--dualboot)
    echo "**"
    echo Dualboot enabled
    echo "**"
    DUALBOOT=${DIR}/../../DualBootPatcher-8.0.0-release/
    EXTRAVER="${EXTRAVER}_dual"
    shift
    ;;
    -y|--dynfs)
    echo "**"
    echo Dynfs enabled
    echo "**"
    EXTRAVER="${EXTRAVER}_dynfs"
    DYNFS="true"
    shift
    ;;
    -e=*|--extraver=*)
    EXTRAVER="${EXTRAVER}_${i#*=}"
    shift
    ;;
    -h|--help)
	do_help
    shift
    ;;
    *)
    echo "Unknown option $i"
    exit 0
    ;;
esac
done

if [ -z $VER ]; then
    echo "No version given (want for example 0.5!), using date"
    VER=$(date -r ${ZIPPATH} +%Y%m%d_%H%M%S)
fi

if [ "${TYPE}" == "AOSP" ]; then
    TARGETZIP="AOSP_${ANDROID_VER}_I9295_spegelius_v${VER}${EXTRAVER}.zip"
elif [ "${TYPE}" == "CM" ]; then
    TARGETZIP="cm-${ANDROID_VER}-${VER}-UNOFFICIAL-jactivelte${EXTRAVER}.zip"
fi

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
    ${DUALBOOT}/patch-file.sh ${WORKDIR}/boot.img -d jflte -p dual --unsupported --ramdisk jflte/AOSP/AOSP --autopatcher Standard
    rm ${WORKDIR}/boot.img
    mv ${WORKDIR}/boot_dual.img ${WORKDIR}/boot.img
    cp ${DUALBOOT}/patches/dualboot.sh ${WORKDIR}

    MOUNTS=${DIR}/${METADIR}/updater-script_template_mounts_dual
    UNMOUNTS=${DIR}/${METADIR}/updater-script_template_unmounts_dual
fi

if [ "${TYPE}" == "AOSP" ]; then
    cp -rf ${DIR}/system/* ${WORKDIR}/system/
fi
if [ "$DYNFS" == "true" ]; then
    cp -r ${DIR}/fscheck ${WORKDIR}
    MOUNTS=${DIR}/${METADIR}/updater-script_template_mounts_dynfs
fi

# zip META_INF
echo "**"
echo Adding META-INF from ${DIR}/${METADIR}
echo "**"
mkdir -p ${DIR}/${METADIR}/META-INF/com/google/android/

if [ "${TYPE}" == "AOSP" ]; then
    WHITESPACE_AVER="28"
elif [ "${TYPE}" == "CM" ]; then
    WHITESPACE_AVER="23"
fi

AVERSTRING="${ANDROID_VER} for GT-I9295"
COUNT=$(expr ${WHITESPACE_AVER} - $(echo $AVERSTRING | wc -c))
for i in $(eval echo "{1..$COUNT}"); do
    AVERSTRING="${AVERSTRING} "
done

VERSTRING="${VER}${EXTRAVER}"
COUNT=$(expr 40 - $(echo $VERSTRING | wc -c))
for i in $(eval echo "{1..$COUNT}"); do
    VERSTRING="${VERSTRING} "
done
echo $AVERSTRING
echo $VERSTRING

cat ${DIR}/${METADIR}/updater-script_template_start | sed "s/ANDROIDVERHERE/${AVERSTRING}*\");/" > ${DIR}/${METADIR}/_temp
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

