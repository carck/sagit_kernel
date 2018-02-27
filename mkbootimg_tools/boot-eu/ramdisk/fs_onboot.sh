#!/system/bin/sh

export PATH=${PATH}:/system/bin:/sbin


MODULES_CHECK=$(ls /system/lib/modules | grep crk_modules.ok | wc -l);
if [ "$MODULES_CHECK" -eq "0" ]; then
	rmmod wlan.ko > /dev/null 2>&1
	umount /system/lib/modules > /dev/null 2>&1
	mount --bind /crk_modules /system/lib/modules
fi;

# disable block iostats
for i in /sys/block/*/queue; do
	echo 0 > $i/iostats
done;