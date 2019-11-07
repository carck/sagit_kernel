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

 # configure governor settings for little cluster
echo "schedutil" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 40000 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/down_rate_limit_us
echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/iowait_boost_enable
echo 500 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/up_rate_limit_us
# online CPU4
echo 1 > /sys/devices/system/cpu/cpu4/online
# configure governor settings for big cluster
echo "schedutil" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor
echo 40000 > /sys/devices/system/cpu/cpu4/cpufreq/schedutil/down_rate_limit_us
echo 1 > /sys/devices/system/cpu/cpu4/cpufreq/schedutil/iowait_boost_enable
echo 500 > /sys/devices/system/cpu/cpu4/cpufreq/schedutil/up_rate_limit_us
