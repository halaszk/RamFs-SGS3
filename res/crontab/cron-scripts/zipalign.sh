#!/sbin/busybox sh
#From Darky's zipalign - Modified to make it actually work.
#Modded by Dorimanx.

(
PROFILE=`cat /data/.siyah/.active.profile`;
. /data/.siyah/$PROFILE.profile;

if [ "$cron_zipalign" == "on" ]; then

	while [ ! `cat /proc/loadavg | cut -c1-4` \< "3.50" ]; do
        	echo "Waiting For CPU to cool down";
        	sleep 30;
	done;

	if [ `pgrep -f "zipalign" | wc -l` \< 5 ]; then
		echo "Starting zipalign, it's will take 2min to finish, please wait.";
		sleep 3;

		/sbin/busybox mount -o remount,rw /system;
		/sbin/busybox mount -o remount,rw /data;

		if [ -e /data/zipalign.log ]; then
			rm -f /data/zipalign.log;
			rm -f /data/zipalign.db;
		fi;

		LOG_FILE=/data/zipalign.log;
		ZIPALIGNDB=/data/zipalign.db;

		if [ ! -e /system/xbin/zipalign ]; then
			cp /res/misc/zipalign /system/xbin/zipalign;
			chmod 755 /system/xbin/zipalign;
		fi;

		if [ -e $LOG_FILE ]; then
			rm $LOG_FILE;
		fi;

		if [ ! -f $ZIPALIGNDB ]; then
			touch $ZIPALIGNDB;
		fi;

		echo "Starting FV Automatic ZipAlign $( date +"%m-%d-%Y %H:%M:%S" )" | tee -a $LOG_FILE;

		for DIR in /data/app; do
			cd $DIR;
			for APK in *.apk; do
				if [ $APK -ot $ZIPALIGNDB ] && [ $(grep "$DIR/$APK" $ZIPALIGNDB | wc -l) -gt 0 ]; then
					echo "Already checked: $DIR/$APK" | tee -a $LOG_FILE;
				else
					ZIPCHECK=`/system/xbin/zipalign -c -v 4 $APK | grep FAILED | wc -l`;

					if [ $ZIPCHECK == "1" ]; then
						echo "Now aligning: $DIR/$APK" | tee -a $LOG_FILE;
						/system/xbin/zipalign -v -f 4 $APK /data/local/$APK;
						cp -f -p /data/local/$APK $APK;
						grep "$DIR/$APK" $ZIPALIGNDB > /dev/null || echo $DIR/$APK >> $ZIPALIGNDB;
					else
						echo "Already aligned: $DIR/$APK" | tee -a $LOG_FILE;
						grep "$DIR/$APK" $ZIPALIGNDB > /dev/null || echo $DIR/$APK >> $ZIPALIGNDB;
					fi;
				fi;
			done;
		done;

		touch $ZIPALIGNDB;
		echo "Automatic ZipAlign finished at $( date +"%m-%d-%Y %H:%M:%S" )" | tee -a $LOG_FILE;
		date +%H:%M-%D-%Z > /data/crontab/cron-zipalign;
		echo "Done! Zipaligned All Apps" >> /data/crontab/cron-zipalign;
		mv /data/local/*.apk /data/app/
		chown system:system /data/app/*
		chmod 644 /data/app/*
	else
		echo "ZipAlign already running, please wait.";
	fi;
fi;
)&

