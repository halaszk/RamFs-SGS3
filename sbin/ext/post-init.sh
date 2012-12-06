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

#mdnie sharpness tweak
if [ "$mdniemod" == "on" ];then
. /sbin/ext/mdnie-sharpness-tweak.sh
fi

# Cortex parent should be ROOT/INIT and not STweaks
nohup /sbin/ext/cortexbrain-tune.sh; 

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

	if [ "$gesture_tweak" == on ]; then
echo "1" > /sys/devices/virtual/misc/touch_gestures/gestures_enabled;
pkill -f "/data/gesture_set.sh";
pkill -f "/sys/devices/virtual/misc/touch_gestures/wait_for_gesture";
nohup /sbin/busybox sh /data/gesture_set.sh;
fi;

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

(
# Stop uci.sh from running all the PUSH Buttons in stweaks on boot.
mount -o remount,rw rootfs;
chown root:system /res/customconfig/actions/ -R;
chmod 6755 /res/customconfig/actions/*;
chmod 6755 /res/customconfig/actions/push-actions/*;
mv /res/customconfig/actions/push-actions/* /res/no-push-on-boot/;

# set root access script.
chmod 6755 /sbin/ext/cortexbrain-tune.sh;

# apply STweaks settings
echo "booting" > /data/.siyah/booting;
pkill -f "com.gokhanmoral.stweaks.app";
sh /res/uci.sh restore;

# restore all the PUSH Button Actions back to there location
mount -o remount,rw rootfs;
mv /res/no-push-on-boot/* /res/customconfig/actions/push-actions/;
pkill -f "com.gokhanmoral.stweaks.app";
rm -f /data/.siyah/booting;
# ==============================================================
# STWEAKS FIXING
# ==============================================================
# change USB mode MTP or Mass Storage
/res/customconfig/actions/usb-mode ${usb_mode};
)&

/sbin/busybox mount -t rootfs -o remount,rw rootfs

##### EFS Backup #####
(
/sbin/busybox sh /sbin/ext/efs-backup.sh
) &

# apply STweaks defaults
sleep 12
/res/uci.sh apply

PIDOFACORE=`pgrep -f "android.process.acore"`;
for i in $PIDOFACORE; do
echo "-800" > /proc/${i}/oom_score_adj;
renice -15 -p $i;
log -p 10 i -t boot "*** do not kill -> android.process.acore ***";
done;

##### init scripts #####

if [ $init_d == on ]; then
/sbin/busybox sh /sbin/ext/run-init-scripts.sh;
fi;
/sbin/busybox sh /sbin/ext/partitions-tune.sh

