#!/sbin/busybox sh

# remount partitions with noatime
for k in $(mount | grep relatime | cut -d " " -f3);
do
	mount -o remount,noatime $k;
done;

#enable kmem interface for everyone
echo 0 > /proc/sys/kernel/kptr_restrict

#disable cpuidle log
echo 0 > /sys/module/cpuidle_exynos4/parameters/log_en

# replace kernel version info for repacked kernels
#cat /proc/version | grep infra && (k=15;for i in 83 105 121 97 104 45 49 46 54 98 49 48;do kmemhelper -t char -n linux_proc_banner -o $k $i;k=`expr $k + 1`;done;)
cat /proc/version | grep infra && (kmemhelper -t string -n linux_proc_banner -o 15 `cat /res/version`)

# sched_mc -> 2 
# "to provide better performance in a underutilised system...
# "...by keeping the group of tasks on a single cpu package...
# "...facilitating cache sharing and reduced off-chip traffic"
#echo 2 > /sys/devices/system/cpu/sched_mc_power_savings
echo "54 108 160 266 350 440 533 640 733 800" > /sys/devices/system/gpu/freq_table
#echo "675 700 750 825 875 975 1075 1125 1175 1200" > /sys/devices/system/gpu/volt_table
echo "1300 1300 1275 1213 1175 1138 1075 1025 975 925 875 863 850 838 825 800 800" > /sys/devices/system/cpu/cpu0/cpufreq/UV_mV_table
# enable KSM.
echo "1" > /sys/kernel/mm/ksm/run;
# pegasusq tweaks
echo "80000" > /sys/devices/system/cpu/cpufreq/pegasusq/sampling_rate;
echo "80" > /sys/devices/system/cpu/cpufreq/pegasusq/up_threshold;
echo "2" > /sys/devices/system/cpu/cpufreq/pegasusq/sampling_down_factor;
echo "5" > /sys/devices/system/cpu/cpufreq/pegasusq/down_differential;
echo "30" > /sys/devices/system/cpu/cpufreq/pegasusq/freq_step;
echo "80" > /sys/devices/system/cpu/cpufreq/pegasusq/up_threshold_at_min_freq;
echo "200000" > /sys/devices/system/cpu/cpufreq/pegasusq/freq_for_responsiveness;
echo "0" > /sys/devices/system/cpu/cpufreq/pegasusq/max_cpu_lock;
echo "0" > /sys/devices/system/cpu/cpufreq/pegasusq/dvfs debug;
echo "0" > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_lock;
echo "800000" > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_freq_1_1;
echo "400000" > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_freq_2_0;
echo "500000" > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_freq_2_1;
echo "400000" > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_freq_3_0;
echo "800000" > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_freq_3_1;
echo "500000" > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_freq_4_0;
echo "200" > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_rq_1_1;
echo "150" > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_rq_2_0;
echo "250" > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_rq_2_1;
echo "300" > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_rq_3_0;
echo "400" > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_rq_3_1;
echo "400" > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_rq_4_0;
# process priority modifications
(
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20;do
sleep 5;
renice 15 `pidof kswapd0`;
renice 3 `pidof android.process.acore`;
renice 3 `pidof android.process.media`;
renice -10 `pidof com.sec.android.app.launcher`;
renice -10 `pidof com.anddoes.launcher`;
renice -10 `pidof com.teslacoilsw.launcher`;
renice -10 `pidof com.sec.android.inputmethod`;
renice -10 `pidof com.cootek.smartinputv5`;
renice -10 `pidof com.swype.android.inputmethod`;
done;
)&

