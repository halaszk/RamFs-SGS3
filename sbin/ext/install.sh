#!/sbin/busybox sh

extract_payload()
{
  payload_extracted=1
  chmod 755 /sbin/read_boot_headers
  eval $(/sbin/read_boot_headers /dev/block/mmcblk0p5)
  load_offset=$boot_offset
  load_len=$boot_len
  cd /
  dd bs=512 if=/dev/block/mmcblk0p5 skip=$load_offset count=$load_len | tar x
}

. /res/customconfig/customconfig-helper
read_defaults
read_config

mount -o remount,rw /system
/sbin/busybox mount -t rootfs -o remount,rw rootfs
payload_extracted=0

cd /

cp -a /res/crontab/ /data/
rm -rf /data/crontab/cron/ > /dev/null 2>&1;
if [ ! -e /data/crontab/custom_jobs ]; then
touch /data/crontab/custom_jobs;
chmod 777 /data/crontab/custom_jobs;
fi;
# update my scripts in case i made change.
cp -a /res/crontab/cron-scripts/* /data/crontab/cron-scripts/

# add gesture_set.sh with default gustures to data to be used by user.
if [ ! -e /data/gesture_set.sh ]; then
 cp -a /res/misc/gesture_set.sh /data/;
fi;

if [ "$install_root" == "on" ];
then
  if [ -s /system/xbin/su ];
  then
    echo "Superuser already exists"
  else
    if [ "$payload_extracted" == "0" ];then
      extract_payload
    fi
    rm -f /system/bin/su
    rm -f /system/xbin/su
    mkdir /system/xbin
    chmod 755 /system/xbin
    xzcat /res/misc/payload/su.xz > /system/xbin/su
    chown 0.0 /system/xbin/su
    chmod 6755 /system/xbin/su

    rm -f /system/app/*uper?ser.apk
    rm -f /system/app/?uper?u.apk
    rm -f /system/app/*chainfire?supersu*.apk
    rm -f /data/app/*uper?ser.apk
    rm -f /data/app/?uper?u.apk
    rm -f /data/app/*chainfire?supersu*.apk
    rm -rf /data/dalvik-cache/*uper?ser.apk*
    rm -rf /data/dalvik-cache/*chainfire?supersu*.apk*
	
	# extract super user app
	xzcat /res/misc/payload/SuperSU.apk.xz > /system/app/SuperSU.apk;
	chown 0.0 /system/app/SuperSU.apk;
	chmod 644 /system/app/SuperSU.apk;
	
	pkill -f "com.noshufou.android.su";
	pkill -f "eu.chinfire.supersu";
  fi
fi;

GMTWEAKS()
{
  if [ "$payload_extracted" == "0" ];then
    extract_payload
  fi
if [ -f /system/app/STweaks.apk ]; then
stmd5sum=`/sbin/busybox md5sum /system/app/STweaks.apk | /sbin/busybox awk '{print $1}'`
stmd5sum_kernel=`cat /res/stweaks_md5`;
if [ "$stmd5sum" != "$stmd5sum_kernel" ]; then
rm -f /system/app/STweaks.apk > /dev/null 2>&1;
rm -f /data/app/com.gokhanmoral.*weaks*.apk > /dev/null 2>&1;
rm -f /data/dalvik-cache/*gokhanmoral.*weak*.apk* > /dev/null 2>&1;
rm -f /cache/dalvik-cache/*gokhanmoral.*weak*.apk* > /dev/null 2>&1;
fi;
fi;

if [ ! -f /system/app/STweaks.apk ]; then
rm -f /data/app/com.gokhanmoral.*weak*.apk > /dev/null 2>&1;
rm -rf /data/data/com.gokhanmoral.*weak* > /dev/null 2>&1;
rm -f /data/dalvik-cache/*gokhanmoral.*weak*.apk* > /dev/null 2>&1;
rm -f /cache/dalvik-cache/*gokhanmoral.*weak*.apk* > /dev/null 2>&1;
xzcat /res/misc/payload/STweaks.apk.xz > /system/app/STweaks.apk;
chown 0.0 /system/app/STweaks.apk;
chmod 644 /system/app/STweaks.apk;
fi;
}
GMTWEAKS;

EXTWEAKS_CLEAN()
{
if [ -f /system/app/Extweaks.apk ] || [ -f /data/app/com.darekxan.extweaks.ap*.apk ]; then
rm -f /system/app/Extweaks.apk > /dev/null 2>&1;
rm -f /data/app/com.darekxan.extweaks.ap*.apk > /dev/null 2>&1;
rm -rf /data/data/com.darekxan.extweaks.app > /dev/null 2>&1;
rm -f /data/dalvik-cache/*com.darekxan.extweaks.app* > /dev/null 2>&1;
fi;
}
EXTWEAKS_CLEAN;

echo "ntfs-3g..."
if [ ! -s /system/xbin/ntfs-3g ];
then
  if [ "$payload_extracted" == "0" ];then
    extract_payload
  fi
  xzcat /res/misc/payload/ntfs-3g.xz > /system/xbin/ntfs-3g
  chown 0.0 /system/xbin/ntfs-3g
  chmod 755 /system/xbin/ntfs-3g
fi

rm -rf /res/misc/payload

/sbin/busybox mount -t rootfs -o remount,rw rootfs
mount -o remount,rw /system
