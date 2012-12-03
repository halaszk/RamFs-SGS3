#!/sbin/busybox sh

#Credits:
# Zacharias.maladroit
# Voku1987
# Collin_ph@xda
# Dorimanx@xda
# Gokhanmoral@xda
# Johnbeetee
# halaszk

# TAKE NOTE THAT LINES PRECEDED BY A "#" IS COMMENTED OUT.
# This script must be activated after init start =< 25sec or parameters from /sys/* will not be loaded.

# read setting from profile

# Get values from profile. since we dont have the recovery source code i cant change the .siyah dir, so just leave it there for history.
PROFILE=`cat /data/.siyah/.active.profile`;
. /data/.siyah/$PROFILE.profile;

FILE_NAME=$0;
PIDOFCORTEX=$$;

# default settings (1000 = 10 seconds)
dirty_expire_centisecs_default=3000;
dirty_writeback_centisecs_default=500;

# battery settings
dirty_expire_centisecs_battery=0;
dirty_writeback_centisecs_battery=0;

# =========
# Renice - kernel thread responsible for managing the swap memory and logs
# =========
renice 15 -p `pgrep -f "kswapd0"`;
renice 15 -p `pgrep -f "logcat"`;

# replace kernel version info for repacked kernels
cat /proc/version | grep infra && (kmemhelper -t string -n linux_proc_banner -o 15 `cat /res/version`);

# ==============================================================
# I/O-TWEAKS 
# ==============================================================
IO_TWEAKS()
{
	if [ "$cortexbrain_io" == on ]; then
		MMC=`ls -d /sys/block/mmc*`;
		ZRM=`ls -d /sys/block/zram*`;

		for z in $ZRM; do
	
			if [ -e $i/queue/rotational ]; then
				echo "0" > $i/queue/rotational;
			fi;

			if [ -e $i/queue/iostats ]; then
				echo "0" > $i/queue/iostats;
			fi;

			if [ -e $i/queue/rq_affinity ]; then
				echo "1" > $i/queue/rq_affinity;
			fi;

			if [ -e $i/queue/read_ahead_kb ]; then
				echo "512" >  $i/queue/read_ahead_kb;
			fi;

			if [ -e $i/queue/max_sectors_kb ]; then
				echo "512" >  $i/queue/max_sectors_kb; # default: 127
			fi;

		done;

		for i in $MMC; do

			if [ -e $i/queue/scheduler ]; then
				echo $scheduler > $i/queue/scheduler;
			fi;

			if [ -e $i/queue/rotational ]; then
				echo "0" > $i/queue/rotational;
			fi;

			if [ -e $i/queue/iostats ]; then
				echo "0" > $i/queue/iostats;
			fi;

			if [ -e $i/queue/read_ahead_kb ]; then
				echo $read_ahead_kb >  $i/queue/read_ahead_kb; # default: 128
			fi;

			if [ -e $i/queue/nr_requests ]; then
				echo "20" > $i/queue/nr_requests; # default: 128
			fi;

			if [ -e $i/queue/iosched/back_seek_penalty ]; then
				echo "1" > $i/queue/iosched/back_seek_penalty; # default: 2
			fi;

			if [ -e $i/queue/iosched/slice_idle ]; then
				echo "2" > $i/queue/iosched/slice_idle; # default: 8
			fi;

			if [ -e $i/queue/iosched/fifo_batch ]; then
				echo "1" > $i/queue/iosched/fifo_batch;
			fi;

		done;

		if [ -e /sys/devices/virtual/bdi/default/read_ahead_kb ]; then
			echo $read_ahead_kb > /sys/devices/virtual/bdi/default/read_ahead_kb;
		fi;

		SDCARDREADAHEAD=`ls -d /sys/devices/virtual/bdi/179*`;
		for i in $SDCARDREADAHEAD; do
			echo $read_ahead_kb > $i/read_ahead_kb;
		done;

		echo "45" > /proc/sys/fs/lease-break-time;

		log -p 10  i -t $FILE_NAME "*** IO_TWEAKS ***: enabled";
	fi;
}
IO_TWEAKS;

# ==============================================================
# KERNEL-TWEAKS
# ==============================================================
KERNEL_TWEAKS()
{
	if [ "$cortexbrain_kernel_tweaks" == on ]; then
		echo "1" > /proc/sys/vm/oom_kill_allocating_task;
		sysctl -w vm.panic_on_oom=0;
	
		log -p 10  i -t $FILE_NAME "*** KERNEL_TWEAKS ***: enabled";
	fi;
}
KERNEL_TWEAKS;

# ==============================================================
# SYSTEM-TWEAKS
# ==============================================================
SYSTEM_TWEAKS()
{
	if [ "$cortexbrain_system" == on ]; then
		# render UI with GPU
		setprop hwui.render_dirty_regions false;
		setprop windowsmgr.max_events_per_sec 240;
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
  /sbin/busybox sysctl -w vm.vfs_cache_pressure=10

# System tweaks: Hardcore speedmod
  # vm tweaks
  echo "12288" > /proc/sys/vm/min_free_kbytes
  echo "1500" > /proc/sys/vm/dirty_writeback_centisecs
  echo "200" > /proc/sys/vm/dirty_expire_centisecs
  echo "60" > /proc/sys/vm/swappiness

		log -p 10  i -t $FILE_NAME "*** SYSTEM_TWEAKS ***: enabled";
	fi;
}
SYSTEM_TWEAKS;

# ==============================================================
# BATTERY-TWEAKS
# ==============================================================
BATTERY_TWEAKS()
{
	if [ "$cortexbrain_battery" == on ]; then

		# USB power support
		for i in `ls /sys/bus/usb/devices/*/power/level`; do
			chmod 777 $i;
			echo "auto" > $i;
		done;
		for i in `ls /sys/bus/usb/devices/*/power/autosuspend`; do
			chmod 777 $i;
			echo "1" > $i;
		done;

		# BUS power support
		buslist="spi i2c sdio";
		for bus in $buslist; do
			for i in `ls /sys/bus/$bus/devices/*/power/control`; do
				chmod 777 $i;
				echo "auto" > $i;
			done;
		done;

		log -p 10  i -t $FILE_NAME "*** BATTERY_TWEAKS ***: enabled";
	fi;
}

# ==============================================================
# CPU-TWEAKS
# ==============================================================

CPU_GOV_TWEAKS()
{
	if [ "$cortexbrain_cpu" == on ]; then
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
  echo "80" > /sys/devices/system/cpu/cpufreq/pegasusq/up_threshold
  echo "$max_cpu_lock" > /sys/devices/system/cpu/cpufreq/pegasusq/max_cpu_lock
  echo "80" > /sys/devices/system/cpu/cpufreq/pegasusq/up_threshold_at_min_freq
  echo "10" > /sys/devices/system/cpu/cpufreq/pegasusq/cpu_down_rate
  echo "$lcdfreq_enable" > /sys/devices/system/cpu/cpufreq/peqasusq/lcdfreq_enable

		log -p 10  i -t $FILE_NAME "*** CPU_GOV_TWEAKS ***: enabled";
	fi;
}

# ==============================================================
# MEMORY-TWEAKS
# ==============================================================
MEMORY_TWEAKS()
{
	if [ "$cortexbrain_memory" == on ]; then
		echo "$dirty_expire_centisecs_default" > /proc/sys/vm/dirty_expire_centisecs;
		echo "$dirty_writeback_centisecs_default" > /proc/sys/vm/dirty_writeback_centisecs;
		echo "20" > /proc/sys/vm/dirty_background_ratio; # default: 10
		echo "20" > /proc/sys/vm/dirty_ratio; # default: 20
		echo "4" > /proc/sys/vm/min_free_order_shift; # default: 4
		echo "1" > /proc/sys/vm/overcommit_memory; # default: 0
		echo "50" > /proc/sys/vm/overcommit_ratio; # default: 50
		echo "128 128" > /proc/sys/vm/lowmem_reserve_ratio;
		echo "3" > /proc/sys/vm/page-cluster; # default: 3
		echo "8192" > /proc/sys/vm/min_free_kbytes;

		log -p 10  i -t $FILE_NAME "*** MEMORY_TWEAKS ***: enabled";
	fi;
}
MEMORY_TWEAKS;

# ==============================================================
# TCP-TWEAKS
# ==============================================================
TCP_TWEAKS()
{
	if [ "$cortexbrain_tcp" == on ]; then
		echo "0" > /proc/sys/net/ipv4/tcp_timestamps;
		echo "1" > /proc/sys/net/ipv4/tcp_tw_reuse;
		echo "1" > /proc/sys/net/ipv4/tcp_sack;
		echo "1" > /proc/sys/net/ipv4/tcp_tw_recycle;
		echo "1" > /proc/sys/net/ipv4/tcp_window_scaling;
		echo "1" > /proc/sys/net/ipv4/tcp_moderate_rcvbuf;
		echo "1" > /proc/sys/net/ipv4/route/flush;
		echo "2" > /proc/sys/net/ipv4/tcp_syn_retries;
		echo "2" > /proc/sys/net/ipv4/tcp_synack_retries;
		echo "10" > /proc/sys/net/ipv4/tcp_fin_timeout;
		echo "0" > /proc/sys/net/ipv4/tcp_ecn;
		echo "262144" > /proc/sys/net/core/wmem_max;
		echo "524288" > /proc/sys/net/core/rmem_max;
		echo "262144" > /proc/sys/net/core/rmem_default;
		echo "262144" > /proc/sys/net/core/wmem_default;
		echo "20480" > /proc/sys/net/core/optmem_max;
		echo "4096 16384 262144" > /proc/sys/net/ipv4/tcp_wmem;
		echo "4096 87380 524288" > /proc/sys/net/ipv4/tcp_rmem;
		echo "4096" > /proc/sys/net/ipv4/udp_rmem_min;
		echo "4096" > /proc/sys/net/ipv4/udp_wmem_min;

		log -p 10  i -t $FILE_NAME "*** TCP_TWEAKS ***: enabled";
	fi;
}
TCP_TWEAKS;

# ==============================================================
# FIREWALL-TWEAKS
# ==============================================================
FIREWALL_TWEAKS()
{
	if [ "$cortexbrain_firewall" == on ]; then
		# ping/icmp protection
		echo "1" > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts;
		echo "1" > /proc/sys/net/ipv4/icmp_echo_ignore_all;
		echo "1" > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses;

		# drop spoof, redirects, etc
		#echo "1" > /proc/sys/net/ipv4/conf/all/rp_filter;
		#echo "1" > /proc/sys/net/ipv4/conf/default/rp_filter;
		#echo "0" > /proc/sys/net/ipv4/conf/all/send_redirects;
		#echo "0" > /proc/sys/net/ipv4/conf/default/send_redirects;
		#echo "0" > /proc/sys/net/ipv4/conf/default/accept_redirects;
		#echo "0" > /proc/sys/net/ipv4/conf/all/accept_source_route;
		#echo "0" > /proc/sys/net/ipv4/conf/default/accept_source_route;

		log -p 10  i -t $FILE_NAME "*** FIREWALL_TWEAKS ***: enabled";
	fi;
}
FIREWALL_TWEAKS;

# ==============================================================
# SCREEN-FUNCTIONS
# ==============================================================

ENABLE_WIFI_PM()
{
if [ "$wifi_pwr" == on ]; then
if [ -e /sys/module/dhd/parameters/wifi_pm ]; then
echo "1" > /sys/module/dhd/parameters/wifi_pm;
fi;
log -p 10 i -t $FILE_NAME "*** WIFI_PM ***: enabled";
fi;
}

DISABLE_WIFI_PM()
{
if [ -e /sys/module/dhd/parameters/wifi_pm ]; then
echo "0" > /sys/module/dhd/parameters/wifi_pm;
log -p 10 i -t $FILE_NAME "*** WIFI_PM ***: disabled";
fi;
}

ENABLE_LOGGER()
{
	if [ "$android_logger" == auto ] || [ "$android_logger" == debug ]; then
		if [ -e /dev/log-sleep ] && [ ! -e /dev/log ]; then
			mv /dev/log-sleep/ /dev/log/
			log -p 10  i -t $FILE_NAME "*** LOGGER ***: enabled";
		fi;
	fi;
}

DISABLE_LOGGER()
{
	if [ "$android_logger" == auto ] || [ "$android_logger" == disabled ]; then
		if [ -e /dev/log ]; then
			mv /dev/log/ /dev/log-sleep/;
			log -p 10  i -t $FILE_NAME "*** LOGGER ***: disabled";
		fi;
	fi;
}

ENABLE_GESTURES()
{
	if [ "$gesture_tweak" == on ]; then
		echo "1" > /sys/devices/virtual/misc/touch_gestures/gestures_enabled;
		pkill -f "/data/gesture_set.sh";
		pkill -f "/sys/devices/virtual/misc/touch_gestures/wait_for_gesture";
		nohup /sbin/busybox sh /data/gesture_set.sh;
		log -p 10  i -t $FILE_NAME "*** GESTURE ***: enabled";
	fi;
}

DISABLE_GESTURES()
{
	if [ `pgrep -f "/data/gesture_set.sh" | wc -l` != "0" ] || [ `pgrep -f "/sys/devices/virtual/misc/touch_gestures/wait_for_gesture" | wc -l` != "0" ] || [ "$gesture_tweak" == off ]; then
		pkill -f "/data/gesture_set.sh";
		pkill -f "/sys/devices/virtual/misc/touch_gestures/wait_for_gesture";
	fi;
	echo "0" > /sys/devices/virtual/misc/touch_gestures/gestures_enabled;
	log -p 10  i -t $FILE_NAME "*** GESTURE ***: disabled";
}


# please don't kill "cortexbrain"
DONT_KILL_CORTEX()
{
	PIDOFCORTEX=`pgrep -f "/sbin/ext/cortexbrain-tune.sh"`;
	for i in $PIDOFCORTEX; do
		echo "-950" > /proc/${i}/oom_score_adj;
	done;
	log -p 10  i -t $FILE_NAME "*** DONT_KILL_CORTEX ***";
}

# set wakeup booster delay to prevent mp3 music shattering when screen turned ON
WAKEUP_DELAY()
{
if [ "$wakeup_delay" != 0 ] && [ ! -e /data/.siyah/booting ]; then
log -p 10  i -t $FILE_NAME "*** WAKEUP_DELAY ${wakeup_delay}sec ***";
sleep $wakeup_delay
fi;
}

WAKEUP_DELAY_SLEEP()
{
if [ "$wakeup_delay" != 0 ] && [ ! -e /data/.siyah/booting ]; then
log -p 10  i -t $FILE_NAME "*** WAKEUP_DELAY_SLEEP ${wakeup_delay}sec ***";
sleep $wakeup_delay;
else
log -p 10  i -t $FILE_NAME "*** WAKEUP_DELAY_SLEEP 3sec ***";
sleep 3;
fi;
}

# check if ROM booting now, then don't wait - creation and deletion of /data/.siyah/booting @> /sbin/ext/post-init.sh
WAKEUP_BOOST_DELAY()
{
if [ ! -e /data/.siyah/booting ] && [ "$wakeup_boost" != 0 ]; then
log -p 10  i -t $FILE_NAME "*** WAKEUP_BOOST_DELAY ${wakeup_boost}sec ***";
sleep $wakeup_boost;
fi;
}

# boost CPU power for fast and no lag wakeup
MEGA_BOOST_CPU_TWEAKS()
{
if [ "$cortexbrain_cpu" == on ]; then

echo "1400000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
echo "1400000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
echo "266" > /sys/devices/system/gpu/min_freq;

log -p 10  i -t $FILE_NAME "*** MEGA_BOOST_CPU_TWEAKS ***";
fi;
}


# set less brightnes is battery is low
AUTO_BRIGHTNESS()
{
	if [ "$cortexbrain_auto_tweak_brightness" == on ]; then
		LEVEL=`cat /sys/class/power_supply/battery/capacity`;
		MAX_BRIGHTNESS=`cat /sys/class/backlight/panel/max_brightness`;
		OLD_BRIGHTNESS=`cat /sys/class/backlight/panel/brightness`;
		NEW_BRIGHTNESS=`$(( MAX_BRIGHTNESS*LEVEL/100 ))`;
		if [ "$NEW_BRIGHTNESS" -le "$OLD_BRIGHTNESS" ]; then
			echo "$NEW_BRIGHTNESS" > /sys/class/backlight/panel/brightness;
		fi;
		log -p 10  i -t $FILE_NAME "*** AUTO_BRIGHTNESS ***";
	fi;
}


# set swappiness in case that no root installed, and zram used or disk swap used
SWAPPINESS()
{
	SWAP_CHECK=`free | grep Swap | awk '{ print $2 }'`;
	if [ "$zram" == 0 ] || [ "$SWAP_CHECK" == 0 ]; then
		echo "0" > /proc/sys/vm/swappiness;
		log -p 10  i -t $FILE_NAME "*** SWAPPINESS ***: disabled";
	else
		echo "60" > /proc/sys/vm/swappiness;
		log -p 10  i -t $FILE_NAME "*** SWAPPINESS ***: enabled";
	fi;
}

TUNE_IPV6()
{
	CISCO_VPN=`find /data/data/com.cisco.anyconnec* | wc -l`;
	if [ "$cortexbrain_ipv6" == on ] || [ "$CISCO_VPN" != 0 ]; then
		echo "0" > /proc/sys/net/ipv6/conf/wlan0/disable_ipv6;
		sysctl -w net.ipv6.conf.all.disable_ipv6=0
		log -p 10  i -t $FILE_NAME "*** TUNE_IPV6 ***: enabled";
	else
		echo "1" > /proc/sys/net/ipv6/conf/wlan0/disable_ipv6;
		sysctl -w net.ipv6.conf.all.disable_ipv6=1
		log -p 10  i -t $FILE_NAME "*** TUNE_IPV6 ***: disabled";
	fi;
}

KERNEL_SCHED_AWAKE()
{
	case "${cfs_tweaks}" in
  0)
    sysctl -w kernel.sched_min_granularity_ns=750000 > /dev/null
    sysctl -w kernel.sched_latency_ns=10000000 > /dev/null
    sysctl -w kernel.sched_wakeup_granularity_ns=2000000 > /dev/null
    ;;
  1)
    sysctl -w kernel.sched_min_granularity_ns=750000 > /dev/null
    sysctl -w kernel.sched_latency_ns=6000000 > /dev/null
    sysctl -w kernel.sched_wakeup_granularity_ns=1000000 > /dev/null
    ;;
  2)
    sysctl -w kernel.sched_min_granularity_ns=200000 > /dev/null
    sysctl -w kernel.sched_latency_ns=400000 > /dev/null
    sysctl -w kernel.sched_wakeup_granularity_ns=100000 > /dev/null
    ;;
esac;

	log -p 10  i -t $FILE_NAME "*** KERNEL_SCHED ***: awake";
}

KERNEL_SCHED_SLEEP()
{
	echo "20000000" > /proc/sys/kernel/sched_latency_ns;
	echo "3000000" > /proc/sys/kernel/sched_wakeup_granularity_ns;
	echo "2500000" > /proc/sys/kernel/sched_min_granularity_ns;
	log -p 10  i -t $FILE_NAME "*** KERNEL_SCHED ***: sleep";
}

# if crond used, then give it root perent - if started by STweaks, then it will be killed in time
CROND_SAFETY()
{
	if [ "$crontab" == on ]; then
		pkill -f "crond";
		/res/crontab_service/service.sh;
		log -p 10  i -t $FILE_NAME "*** CROND_SAFETY ***";
	fi;
}

DISABLE_NMI()
{
	if [ -e /proc/sys/kernel/nmi_watchdog ]; then
		echo "0" > /proc/sys/kernel/nmi_watchdog;
		log -p 10  i -t $FILE_NAME "*** NMI ***: disable";
	fi;
}

ENABLE_NMI()
{
	if [ -e /proc/sys/kernel/nmi_watchdog ]; then
		echo "1" > /proc/sys/kernel/nmi_watchdog;
		log -p 10  i -t $FILE_NAME "*** NMI ***: enabled";
	fi;
}


# ==============================================================
# TWEAKS: if Screen-ON
# ==============================================================
AWAKE_MODE()
{
	ENABLE_LOGGER;

	KERNEL_SCHED_AWAKE;
	
	WAKEUP_DELAY;
	
#	echo "$scaling_governor" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor;
#	cp -a /tmp/$scaling_governor/* /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor/$scaling_governor;
	
	MEGA_BOOST_CPU_TWEAKS;
	
	ENABLE_GESTURES;
	
	WAKEUP_BOOST_DELAY;

	# set default values
	echo "$dirty_expire_centisecs_default" > /proc/sys/vm/dirty_expire_centisecs;
	echo "$dirty_writeback_centisecs_default" > /proc/sys/vm/dirty_writeback_centisecs;

	# set I/O-Scheduler
	echo "$scheduler" > /sys/block/mmcblk0/queue/scheduler;
	echo "$scheduler" > /sys/block/mmcblk1/queue/scheduler;
	echo "$GPUFREQ1" > /sys/devices/system/gpu/min_freq;

	echo "50" > /proc/sys/vm/vfs_cache_pressure;
	
	DISABLE_WIFI_PM;

	TUNE_IPV6;

	#CPU_GOV_TWEAKS;
	
	if [ "$cortexbrain_cpu" == on ]; then
	# set CPU speed
	echo "$scaling_min_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
	echo "$scaling_max_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
	fi;

	# set wifi.supplicant_scan_interval
	setprop wifi.supplicant_scan_interval $supplicant_scan_interval;

	# set the vibrator - force in case it's has been reseted
#	echo "$pwm_val" > /sys/vibrator/pwm_val;

	ENABLE_NMI;

	AUTO_BRIGHTNESS;

	DONT_KILL_CORTEX;

	log -p 10  i -t $FILE_NAME "*** AWAKE Normal Mode ***";
}

# ==============================================================
# TWEAKS: if Screen-OFF
# ==============================================================
SLEEP_MODE()
{
	# we only read the config when screen goes off ...
	PROFILE=`cat /data/.siyah/.active.profile`;
	. /data/.siyah/$PROFILE.profile;
	
	WAKEUP_DELAY_SLEEP;

	if [ "$cortexbrain_cpu" == on ]; then
	echo "$standby_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
	fi;

	KERNEL_SCHED_SLEEP;

	DISABLE_GESTURES;

	TUNE_IPV6;

	BATTERY_TWEAKS;

	CROND_SAFETY;

	SWAPPINESS;
	
	ENABLE_WIFI_PM;

	if [ "$cortexbrain_cpu" == on ]; then

# reduce deepsleep CPU speed, SUSPEND mode
echo "$scaling_min_suspend_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
echo "$scaling_max_suspend_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;

# set CPU-Tweak
#CPU_GOV_TWEAKS;
fi;


		# set wifi.supplicant_scan_interval
		if [ "$supplicant_scan_interval" \< 180 ]; then
			setprop wifi.supplicant_scan_interval 360;
		fi;

		# set settings for battery -> don't wake up "pdflush daemon"
		echo "$dirty_expire_centisecs_battery" > /proc/sys/vm/dirty_expire_centisecs;
		echo "$dirty_writeback_centisecs_battery" > /proc/sys/vm/dirty_writeback_centisecs;
		
			# set disk I/O sched to noop simple and battery saving.
		echo "$sleep_scheduler" > /sys/block/mmcblk0/queue/scheduler;
		echo "$sleep_scheduler" > /sys/block/mmcblk1/queue/scheduler;

		# set battery value
		echo "10" > /proc/sys/vm/vfs_cache_pressure; # default: 100

		DISABLE_NMI;

		log -p 10  i -t $FILE_NAME "*** SLEEP mode ***";

		DISABLE_LOGGER;
		log -p 10  i -t $FILE_NAME "*** SCREEN OFF BUT POWERED mode ***";
}

# ==============================================================
# Background process to check screen state
# ==============================================================

# Dynamic value do not change/delete
cortexbrain_background_process=1;

if [ "$cortexbrain_background_process" == 1 ] && [ `pgrep -f "cat /sys/power/wait_for_fb_sleep" | wc -l` == 0 ] && [ `pgrep -f "cat /sys/power/wait_for_fb_wake" | wc -l` == 0 ]; then
	(while [ 1 ]; do
		# AWAKE State. all system ON.
		cat /sys/power/wait_for_fb_wake > /dev/null 2>&1;
		AWAKE_MODE;
		sleep 3;

		# SLEEP state. All system to power save.
		cat /sys/power/wait_for_fb_sleep > /dev/null 2>&1;
		SLEEP_MODE;
	done &);
else
	if [ "$cortexbrain_background_process" == 0 ]; then
		echo "Cortex background disabled!"
	else
		echo "Cortex background process already running!";
	fi;
fi;

# ==============================================================
# Logic Explanations
#
# This script will manipulate all the system / cpu / battery behavior
# Based on chosen STWEAKS profile+tweaks and based on SCREEN ON/OFF state.
#
# When User select battery/default profile all tuning will be toward battery save.
# But user loose performance -20% and get more stable system and more battery left.
#
# When user select performance profile, tuning will be to max performance on screen ON.
# When screen OFF all tuning switched to max power saving. as with battery profile,
# So user gets max performance and max battery save but only on screen OFF.
#
# This script change governors and tuning for them on the fly.
# Also switch on/off hotplug CPU core based on screen on/off.
# This script reset battery stats when battery is 100% charged.
# This script tune Network and System VM settings and ROM settings tuning.
# This script changing default MOUNT options and I/O tweaks for all flash disks and ZRAM.
#
# TODO: add more description, explanations & default vaules ...
#
