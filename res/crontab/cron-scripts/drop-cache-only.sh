#!/sbin/busybox sh

PROFILE=`cat /data/.siyah/.active.profile`;
. /data/.siyah/$PROFILE.profile;

if [ "$cron_drop_cache" == "on" ]; then

	MEM_ALL=`free | grep Mem | awk '{ print $2 }'`;
	MEM_USED=`free | grep Mem | awk '{ print $3 }'`;
	MEM_USED_CALC=$(($MEM_USED*100/$MEM_ALL));

	# do clean cache only if cache uses 50% of free memory.
	if [ "$MEM_USED_CALC" \> 50 ]; then

		# wait till CPU is idle.
		while [ ! `cat /proc/loadavg | cut -c1-4` \< "3.50" ]; do
			echo "Waiting For CPU to cool down";
			sleep 30;
		done;

		sync;
		sysctl -w vm.drop_caches=3
		sync;
		sysctl -w vm.drop_caches=1
		sync;
		date +%H:%M-%D-%Z > /data/crontab/cron-clear-ram-cache;
		echo "Cache above 50%! Cleaned RAM Cache" >> /data/crontab/cron-clear-ram-cache;
	fi;
fi;
