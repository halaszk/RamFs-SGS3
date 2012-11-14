#!/sbin/busybox sh
# Logging
#/sbin/busybox cp /data/user.log /data/user.log.bak
#/sbin/busybox rm /data/user.log
#exec >>/data/user.log
#exec 2>&1

mkdir /data/.siyah
chmod 777 /data/.siyah
ccxmlsum=`md5sum /res/customconfig/customconfig.xml | awk '{print $1}'`
if [ "a${ccxmlsum}" != "a`cat /data/.siyah/.ccxmlsum`" ];
then
#  rm -f /data/.siyah/*.profile
  echo ${ccxmlsum} > /data/.siyah/.ccxmlsum
fi
[ ! -f /data/.siyah/default.profile ] && cp /res/customconfig/default.profile /data/.siyah
[ ! -f /data/.siyah/battery.profile ] && cp /res/customconfig/battery.profile /data/.siyah/battery.profile
[ ! -f /data/.siyah/performance.profile ] && cp /res/customconfig/performance.profile /data/.siyah/performance.profile

. /res/customconfig/customconfig-helper
read_defaults
read_config

if [ "$gpuandpowersavetweaks" == "on" ];then
# enable Hardware Rendering
setprop video.accelerate.hw 1;
setprop debug.performance.tuning 1;
setprop debug.sf.hw 1;
setprop persist.sys.use_dithering 1;
setprop persist.sys.ui.hw true; # ->reported as problem maker in some roms.

# render UI with GPU
setprop hwui.render_dirty_regions false;
setprop windowsmgr.max_events_per_sec 120;
setprop profiler.force_disable_err_rpt 1;
setprop profiler.force_disable_ulog 1;

# Proximity tweak
setprop mot.proximity.delay 15;

# more Tweaks
setprop dalvik.vm.execution-mode int:jit;
setprop persist.adb.notify 0;
setprop pm.sleep_mode 1;
fi

#mdnie sharpness tweak
if [ "$mdniemod" == "on" ];then
. /sbin/ext/mdnie-sharpness-tweak.sh
fi

if [ "$logger" == "on" ];then
insmod /lib/modules/logger.ko
fi

# disable debugging on some modules
if [ "$logger" == "off" ];then
  rm -rf /dev/log
  echo 0 > /sys/module/ump/parameters/ump_debug_level
  echo 0 > /sys/module/mali/parameters/mali_debug_level
  echo 0 > /sys/module/kernel/parameters/initcall_debug
  echo 0 > /sys//module/lowmemorykiller/parameters/debug_level
  echo 0 > /sys/module/earlysuspend/parameters/debug_mask
  echo 0 > /sys/module/alarm/parameters/debug_mask
  echo 0 > /sys/module/alarm_dev/parameters/debug_mask
  echo 0 > /sys/module/binder/parameters/debug_mask
  echo 0 > /sys/module/xt_qtaguid/parameters/debug_mask
fi

# for ntfs automounting
insmod /lib/modules/fuse.ko
mount -o remount,rw /
mkdir -p /mnt/ntfs
chmod 777 /mnt/ntfs
mount -o mode=0777,gid=1000 -t tmpfs tmpfs /mnt/ntfs
mount -o remount,ro /

/sbin/busybox sh /sbin/ext/install.sh

##### Early-init phase tweaks #####
/sbin/busybox sh /sbin/ext/tweaks.sh

/sbin/busybox mount -t rootfs -o remount,ro rootfs

##### EFS Backup #####
(
/sbin/busybox sh /sbin/ext/efs-backup.sh
) &

# apply STweaks defaults
sleep 12
/res/uci.sh apply

##### init scripts #####
/sbin/busybox sh /sbin/ext/run-init-scripts.sh
