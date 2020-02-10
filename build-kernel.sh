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
	if [ -e "$KERNELDIR"/mkbootimg_tools/$MODEL/ramdisk/crk_modules/wlan.ko ]; then
		rm "$KERNELDIR"/mkbootimg_tools/$MODEL/ramdisk/crk_modules/*.ko;
	fi;
	if [ -e "$KERNELDIR"/arch/arm64/boot/Image.gz-dtb ]; then
		rm "$KERNELDIR"/arch/arm64/boot/Image.gz-dtb;
	fi;

	if [ -e "$KERNELDIR"/READY-KERNEL/boot.img ]; then
		rm "$KERNELDIR"/READY-KERNEL/boot.img;
	fi;

	PYTHON_CHECK=$(ls -la /usr/bin/python | grep python3 | wc -l);
	PYTHON_WAS_3=0;

	if [ "$PYTHON_CHECK" -eq "1" ] && [ -e /usr/bin/python2 ]; then
		if [ -e /usr/bin/python2 ]; then
			rm /usr/bin/python
			ln -s /usr/bin/python2 /usr/bin/python
			echo "Switched to Python2 for building kernel will switch back when done";
			PYTHON_WAS_3=1;
		else
			echo "You need Python2 to build this kernel. install and come back."
			exit 1;
		fi;
	else
		echo "Python2 is used! all good, building!";
	fi;

	# remove all old modules before compile
	for i in $(find "$KERNELDIR"/ -name "*.ko"); do
		rm -f "$i";
	done;

	# Idea by savoca
	NR_CPUS=$(grep -c ^processor /proc/cpuinfo)

	if [ "$NR_CPUS" -le "2" ]; then
		NR_CPUS=4;
		echo "Building kernel with 4 CPU threads";
	else
		echo "Building kernel with $NR_CPUS CPU threads";
	fi;

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
			cp -av "$i" "$KERNELDIR"/mkbootimg_tools/$MODEL/ramdisk/crk_modules/;
		done;

		chmod 644 "$KERNELDIR"/mkbootimg_tools/$MODEL/ramdisk/crk_modules/*.ko

		if [ "$PYTHON_WAS_3" -eq "1" ]; then
			rm /usr/bin/python
			ln -s /usr/bin/python3 /usr/bin/python
		fi;

		sync

		pushd "$KERNELDIR"/mkbootimg_tools;
		"$KERNELDIR"/mkbootimg_tools/mkboot $MODEL "Kernel-${VERSION}".img;
		mv "$KERNELDIR"/mkbootimg_tools/"Kernel-${VERSION}".img "$KERNELDIR"/magisk/boot.img;
		pushd "$KERNELDIR"/magisk/;
		sh boot_patch.sh boot.img;
		popd;
		mv "$KERNELDIR"/magisk/new-boot.img "$KERNELDIR"/READY-KERNEL/boot.img;
		popd;

		#cp "$KERNELDIR"/mkbootimg_tools/boot2.img "$KERNELDIR"/READY-KERNEL/boot.img
		#cd "$KERNELDIR"/READY-KERNEL;
		#zip -r Kernel-SAGIT-T-"$(date +"[%H-%M]-[%d-%m]-N")".zip * >/dev/null
		#mv *.zip "$KERNELDIR"/

		echo "Cleaning";
		rm "$KERNELDIR"/arch/arm64/boot/Image.gz-dtb;
		rm -rf "$KERNELDIR"/mkbootimg_tools/$MODEL/kernel;
		rm -rf "$KERNELDIR"/mkbootimg_tools/$MODEL/ramdisk/crk_modules/*.ko;
		echo "All Done";
	else
		if [ "$PYTHON_WAS_3" -eq "1" ]; then
			rm /usr/bin/python
			ln -s /usr/bin/python3 /usr/bin/python
		fi;

		# with red-color
		echo -e "\e[1;31mKernel STUCK in BUILD! no Image.gz-dtb exist\e[m"
	fi;
}


BUILD_NOW "boot";

#./sepolicy-inject -s system_server -t rootfs -c system -p module_load -P sepolicy
#./sepolicy-inject -s shell -t rootfs -c file -p getattr -P sepolicy
#./sepolicy-inject -s mt_daemon -t rootfs -c dir -p read -P sepolicy2
#./sepolicy-inject -s mt_daemon -t rootfs -c lnk_file -p getattr -P sepolicy
#./sepolicy-inject -s mt_daemon -t storage_file -c dir -p getattr -P sepolicy
#./sepolicy-inject -s mt_daemon -t adsprpcd_file -c dir -p getattr -P sepolicy
#./sepolicy-inject -s mt_daemon -t cache_file -c dir -p getattr -P sepolicy
#./sepolicy-inject -s mt_daemon -t tmpfs -c dir -p search -P sepolicy2
