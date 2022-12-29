#!/bin/bash
clear

LANG=C
VERSION="V1.6"

# What you need installed to compile
# gcc, gpp, cpp, c++, g++, lzma, lzop, ia32-libs flex

# What you need to make configuration easier by using xconfig
# qt4-dev, qmake-qt4, pkg-config

# toolchain is already exist and set! in kernel git. android-toolchain-arm64/bin/

# location
KERNELDIR=$(readlink -f .);

KERNEL_CONFIG_FILE=sagit_user_defconfig;

BUILD_NOW()
{
	MODEL=$1
	echo "Initialising................."
	echo "Building for ${MODEL}"
	if [ -e "$KERNELDIR"/mkbootimg_tools/$MODEL/kernel ]; then
		rm "$KERNELDIR"/mkbootimg_tools/$MODEL/kernel;
	fi;

	if [ -e "$KERNELDIR"/READY-KERNEL/boot.img ]; then
		rm "$KERNELDIR"/READY-KERNEL/boot.img;
	fi;

	# Idea by savoca
	NR_CPUS=$(grep -c ^processor /proc/cpuinfo)

	if [ "$NR_CPUS" -le "2" ]; then
		NR_CPUS=4;
		echo "Building kernel with 4 CPU threads";
	else
		echo "Building kernel with $NR_CPUS CPU threads";
	fi;

	time make clean

	# build config
	time make ARCH=arm64 sagit_user_defconfig

	# build kernel and modules
	time make ARCH=arm64 CROSS_COMPILE=android-toolchain-arm64/bin/aarch64-SAGIT-linux-android- -j $NR_CPUS

	STRIP=android-toolchain-arm64/bin/aarch64-SAGIT-linux-android-strip

	cp "$KERNELDIR"/.config "$KERNELDIR"/arch/arm64/configs/"$KERNEL_CONFIG_FILE";

	if [ -e "$KERNELDIR"/arch/arm64/boot/Image.gz-dtb ]; then

		stat "$KERNELDIR"/arch/arm64/boot/Image.gz-dtb;

		# move the compiled Image.gz-dtb and modules into the READY-KERNEL working directory
		echo "Move compiled objects........"

		cp "$KERNELDIR"/arch/arm64/boot/Image.gz-dtb mkbootimg_tools/$MODEL/kernel;

		for i in $(find "$KERNELDIR" -name '*.ko'); do
			$STRIP -g "$i"
			cp -av "$i" "$KERNELDIR"/sagit_wlan_magisk/system/vendor/lib/modules/;
		done;

		chmod 644 "$KERNELDIR"/mkbootimg_tools/$MODEL/ramdisk/crk_modules/*.ko

		sync

		pushd "$KERNELDIR"/mkbootimg_tools;
		"$KERNELDIR"/mkbootimg_tools/mkboot $MODEL "Kernel-${VERSION}".img;
		mv "$KERNELDIR"/mkbootimg_tools/"Kernel-${VERSION}".img "$KERNELDIR"/magisk/boot.img;
		pushd "$KERNELDIR"/magisk/;
		sh boot_patch.sh boot.img;
		popd;
		mv "$KERNELDIR"/magisk/new-boot.img "$KERNELDIR"/READY-KERNEL/boot.img;
		popd;


		echo "Cleaning";
		rm "$KERNELDIR"/arch/arm64/boot/Image.gz-dtb;
		rm -rf "$KERNELDIR"/mkbootimg_tools/$MODEL/kernel;
		rm -rf "$KERNELDIR"/mkbootimg_tools/$MODEL/ramdisk/crk_modules/*.ko;
		echo "All Done";
	fi;
}


BUILD_NOW "boot";
