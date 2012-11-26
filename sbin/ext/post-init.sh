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

# file system tweaks
  /sbin/busybox sysctl -w fs.inotify.max_queued_events=32000
  /sbin/busybox sysctl -w fs.file-max=524288
  /sbin/busybox sysctl -w fs.inotify.max_user_instances=256
  /sbin/busybox sysctl -w fs.inotify.max_user_watches=10240
  /sbin/busybox sysctl -w fs.lease-break-time=10

  # kernel setting tweaks
  /sbin/busybox sysctl -w kernel.msgmax=65536
  /sbin/busybox sysctl -w kernel.msgmni=2048
  /sbin/busybox sysctl -w kernel.panic=10
  /sbin/busybox sysctl -w kernel.random.read_wakeup_threshold=128
  /sbin/busybox sysctl -w kernel.random.write_wakeup_threshold=256
  /sbin/busybox sysctl -w kernel.sched_latency_ns=18000000
  /sbin/busybox sysctl -w kernel.sched_wakeup_granularity_ns=3000000
  /sbin/busybox sysctl -w kernel.sched_min_granularity_ns=1500000
  /sbin/busybox sysctl -w kernel.sem='500 512000 64 2048'
  /sbin/busybox sysctl -w kernel.shmmax=268435456
  /sbin/busybox sysctl -w kernel.threads-max=524288

  # net tweaks
  /sbin/busybox sysctl -w net.core.rmem_max=524288
  /sbin/busybox sysctl -w net.core.wmem_max=524288
  /sbin/busybox sysctl -w net.ipv4.tcp_rmem='6144 87380 524288'
  /sbin/busybox sysctl -w net.ipv4.tcp_tw_recycle=1
  /sbin/busybox sysctl -w net.ipv4.tcp_wmem='6144 87380 524288'

  # vm tweaks
  /sbin/busybox sysctl -w vm.dirty_background_ratio=70
  /sbin/busybox sysctl -w vm.dirty_expire_centisecs=250
  /sbin/busybox sysctl -w vm.dirty_ratio=90
  /sbin/busybox sysctl -w vm.dirty_writeback_centisecs=500
  /sbin/busybox sysctl -w vm.min_free_kbytes=4096
  /sbin/busybox sysctl -w vm.swappiness=60
  /sbin/busybox sysctl -w vm.vfs_cache_pressure=10
  /sbin/busybox sysctl -w vm.drop_caches=3

# System tweaks: Hardcore speedmod
  # vm tweaks
  echo "12288" > /proc/sys/vm/min_free_kbytes
  echo "1500" > /proc/sys/vm/dirty_writeback_centisecs
  echo "200" > /proc/sys/vm/dirty_expire_centisecs
  echo "0" > /proc/sys/vm/swappiness

  # Pegasus CPU hotplug tweaks
  echo "500000" > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_freq_1_1
  echo "800000" > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_freq_2_1
  echo "800000" > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_freq_3_1
  echo "400000" > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_freq_2_0
  echo "600000" > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_freq_3_0
  echo "600000" > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_freq_4_0

  echo "100" > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_rq_1_1
  echo "100" > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_rq_2_0
  echo "200" > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_rq_2_1
  echo "200" > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_rq_3_0
  echo "300" > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_rq_3_1
  echo "300" > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_rq_4_0

  echo "10" > /sys/devices/system/cpu/cpufreq/pegasusq/cpu_down_rate

  # TCP tweaks
  echo "2" > /proc/sys/net/ipv4/tcp_syn_retries
  echo "2" > /proc/sys/net/ipv4/tcp_synack_retries
  echo "10" > /proc/sys/net/ipv4/tcp_fin_timeout

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
