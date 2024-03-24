#!/bin/bash
# this script should be run by 61-sd-cards-auto-mount.rules

message() {
        logger -s "mount.sdcard.sh: $1"
        if [ -x "$(command -v /oem/usr/bin/psplash-write)" ]; then
                /oem/usr/bin/psplash-write "MSG $1"
        fi
}

find_update_image() {
        IMAGE_FILE=$(ls /mnt/sdcard/VISION_OEM_*.img)
        MATCHING_FILES_N=$(echo ${IMAGE_FILE} | wc -w)
        if [ ${MATCHING_FILES_N} -eq 0 ]; then
                message "no update images found"
                echo ""
        elif [ ${MATCHING_FILES_N} -eq 1 ]; then
                message "found: ${IMAGE_FILE}, attempting update"
                echo ${IMAGE_FILE}
        else
                message "found more then 1 image file ${IMAGE_FILE}"
                echo ""
        fi
}

init_splash_screen() {
        /oem/usr/bin/psplash > /dev/null 2>&1 &
        sleep .2
        /oem/usr/bin/psplash-write "MSG START UPDATING..."
        /oem/usr/bin/psplash-write "PROGRESS 0"
}

do_upgrade() {
        UPDATE_IMG_FILE=$1
        # stop all vision processes
        for SVC in $(grep -l /oem/usr/bin/ /etc/init.d/* | sort -r);
        do
                $SVC stop
        done
        
        sleep 5 # allow sometime to finish processes

        if [ -x "$(command -v /oem/usr/bin/psplash-write)" ]; then
                init_splash_screen
        fi
        umount /oem

        message "updating /oem"
        dd if=$UPDATE_IMG_FILE of=/dev/mmcblk0p7 bs=4M

        touch /tmp/oem.upgraded

	echo timer > /sys/devices/platform/leds/leds/green/trigger
	echo 500 > /sys/devices/platform/leds/leds/green/delay_on
	echo 500 > /sys/devices/platform/leds/leds/green/delay_off

        message "updated services, exiting normally"
        return 0
}

do_mount() {
        # $1 = fstype
        # $2 = device

        declare -A fstype2cmd
        fstype2cmd=(
                ["ntfs"]="/sbin/mount.ntfs -o rw,uid=1000,gid=1000,dmask=022,fmask=133,noatime"
                ["exfat"]="/sbin/mount.exfat -o rw,uid=1000,gid=1000,dmask=022,fmask=133,noatime"
                ["vfat"]="/bin/mount -t vfat -o rw,uid=1000,gid=1000,dmask=022,fmask=133,noatime"
                ["ext2"]="/bin/mount -t ext2 -o users,exec,noatime"
                ["ext3"]="/bin/mount -t ext3 -o users,exec,noatime"
                ["ext4"]="/bin/mount -t ext4 -o users,exec,noatime"
        )
        cmd=${fstype2cmd[${1}]}

        logger -s "mounting using $1 $2 ${cmd}"
        ${cmd} $2 /mnt/sdcard
}


if { set -C; 2>/dev/null >/tmp/vision-upgrade.lock; }; then
        trap "rm -f /tmp/vision-upgrade.lock" EXIT
else
        message already running
        exit 0
fi
set +C
if [ $1 = "mount" ]; then 
        if mountpoint -q -- /mnt/sdcard; then
                message "/mnt/sdcard is already mounted. no update will be made"
                exit 1
        fi
        do_mount $2 $3

        IMG_FILE=$(find_update_image)
        if [[ -z ${IMG_FILE} ]]; then
                message "update is impossible"
                echo default-on > /sys/devices/platform/leds/leds/green/trigger
                exit 1
        fi

        IMG_VERSION=${IMG_FILE:11:-4}
        CUR_VERSION=$(cat /oem/etc/vision/version)

        message "doing update: ${CUR_VERSION} -> ${IMG_VERSION}"

        if ! do_upgrade ${IMG_FILE}; then
                message "update failed"
                exit 1
        fi
        message "updated successfully with image ${IMG_FILE}"
elif [ $1 = "umount" ]; then
	message "umount"
        /bin/umount /mnt/sdcard
        [[ -e /tmp/oem.upgraded ]] && rm /tmp/oem.upgraded && reboot
        echo none > /sys/devices/platform/leds/leds/green/trigger
else
        message "called with wrong parameter $1"
fi
