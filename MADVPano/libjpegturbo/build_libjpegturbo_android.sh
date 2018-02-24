# https://github.com/libjpeg-turbo/libjpeg-turbo.git

NDK_PATH="/Applications/android-ndk-r12b/"
BUILD_PLATFORM="darwin-x86_64"
TOOLCHAIN_VERSION="4.9"
ANDROID_VERSION="21"

mkdir -p libs/android/

buildForArch() {
	rm -rf built_android
	mkdir -p built_android
	cd built_android

	HOST=$1
	SYSROOT=$2
	ANDROID_CFLAGS=$3
	OTHER_ARGS=$4
	
    echo "Build lib(s) for $HOST..."
    TOOLCHAIN=${NDK_PATH}/toolchains/${HOST}-${TOOLCHAIN_VERSION}/prebuilt/${BUILD_PLATFORM}
    ANDROID_INCLUDES="-I${SYSROOT}/usr/include -I${TOOLCHAIN}/include"
    export CPP=${TOOLCHAIN}/bin/${HOST}-cpp
    export AR=${TOOLCHAIN}/bin/${HOST}-ar
    export AS=${TOOLCHAIN}/bin/${HOST}-as
    export NM=${TOOLCHAIN}/bin/${HOST}-nm
    export CC=${TOOLCHAIN}/bin/${HOST}-gcc
    export LD=${TOOLCHAIN}/bin/${HOST}-ld
    export RANLIB=${TOOLCHAIN}/bin/${HOST}-ranlib
    export OBJDUMP=${TOOLCHAIN}/bin/${HOST}-objdump
    export STRIP=${TOOLCHAIN}/bin/${HOST}-strip
    
	sh ../configure --host="${HOST}" \
		CFLAGS="${ANDROID_INCLUDES} ${ANDROID_CFLAGS} -O3 -fPIE" \
		CPPFLAGS="${ANDROID_INCLUDES} ${ANDROID_CFLAGS}" \
		LDFLAGS="${ANDROID_CFLAGS} -pie" --with-simd ${OTHER_ARGS}
    make
 
    mkdir -p ../libs/android/$HOST
    mv .libs/libjpeg.a ../libs/android/$HOST/libjpeg.a
    mv .libs/libjpeg.so ../libs/android/$HOST/libjpeg.so
    mv .libs/libturbojpeg.a ../libs/android/$HOST/libturbojpeg.a
    mv .libs/libturbojpeg.so ../libs/android/$HOST/libturbojpeg.so

	cd ..
	rm -rf built_android
}

# 32-bit ARMv7 build
HOST=arm-linux-androideabi
SYSROOT=${NDK_PATH}/platforms/android-${ANDROID_VERSION}/arch-arm
#ANDROID_CFLAGS="-march=armv7-a -mfloat-abi=softfp -fprefetch-loop-arrays \
#				--sysroot=${SYSROOT}"
ANDROID_CFLAGS="--sysroot=${SYSROOT}" 
buildForArch $HOST $SYSROOT $ANDROID_CFLAGS ${1+"$@"}

# 64-bit ARMv8 build
HOST=aarch64-linux-android
SYSROOT=${NDK_PATH}/platforms/android-${ANDROID_VERSION}/arch-arm64
ANDROID_CFLAGS="--sysroot=${SYSROOT}"
buildForArch $HOST $SYSROOT $ANDROID_CFLAGS ${1+"$@"}

# MIPS build
HOST=mipsel-linux-android
SYSROOT=${NDK_PATH}/platforms/android-${ANDROID_VERSION}/arch-mips
ANDROID_CFLAGS="--sysroot=${SYSROOT}"
buildForArch $HOST $SYSROOT $ANDROID_CFLAGS ${1+"$@"}

 MIPS64 build
HOST=mips64el-linux-android
SYSROOT=${NDK_PATH}/platforms/android-${ANDROID_VERSION}/arch-mips64
ANDROID_CFLAGS="--sysroot=${SYSROOT}"
buildForArch $HOST $SYSROOT $ANDROID_CFLAGS ${1+"$@"}

 x86 build
HOST=x86
SYSROOT=${NDK_PATH}/platforms/android-${ANDROID_VERSION}/arch-x86
ANDROID_CFLAGS="--sysroot=${SYSROOT}"
buildForArch $HOST $SYSROOT $ANDROID_CFLAGS ${1+"$@"}

# x86_64 build
HOST=x86_64
SYSROOT=${NDK_PATH}/platforms/android-${ANDROID_VERSION}/arch-x86_64
ANDROID_CFLAGS="--sysroot=${SYSROOT}"
buildForArch $HOST $SYSROOT $ANDROID_CFLAGS ${1+"$@"}

