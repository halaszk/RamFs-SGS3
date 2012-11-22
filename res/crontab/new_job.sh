#!/sbin/busybox sh

# Created By Dorimanx and Dairinin

if [ "a$1" != "a" ] && [ -e /system/xbin/busybox ]; then
	cron_localtime () {
		local localtime=$1;
		shift;
		date -u --date=@$(date --date="$localtime" +%s) "+%-M %-H * * *    $*";
	}

	plan_cron_job () {
		local desired_time=$1;
		shift;
		local your_cron_job=$*;

		local tmpfile=$(mktemp);
		crontab -l > $tmpfile;
		# edit it, for example, cut existing job with sed
		sed -i "\~$your_cron_job~ d" $tmpfile;
		cron_localtime $desired_time $your_cron_job >> $tmpfile;
		crontab $tmpfile;
		rm -f $tmpfile;
		crontab -l;
	}
	plan_cron_job $1 $2
else
	if [ ! -e /system/xbin/busybox ]; then
		echo "You dont have busybox that support cron service, update and try again";
	else
		echo "input time and script to run, example: "05:00" "/sbin/busybox sh YOUR SCRIPT PATH HERE" , this will run 'Your Script' at 05:00AM by cron";
	fi;
fi;

