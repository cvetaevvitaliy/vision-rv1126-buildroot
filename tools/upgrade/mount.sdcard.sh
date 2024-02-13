#!/bin/bash
# this script should be run by 61-sd-cards-auto-mount.rules

message() {
        logger -s "mount.sdcard.sh: $1"
}

find_update_image() {
        TEMPLATE=".*VISION_OEM_([[:digit:]]{1,3}\.){3}img$"

        IMAGE_FILE=$(ls /mnt/sdcard |egrep ${TEMPLATE})
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

do_upgrade() {
        UPDATE_IMG_FILE=$1
        # stop all vision processes
        for PID in `ps ax | awk '{ if ($5 ~ /vision/) print $1}'`;
        do
                kill -9 $PID
        done
        sleep 5 # allow sometime to finish processes
        umount /oem

        message "updating /oem"
        dd if=$UPDATE_IMG_FILE of=/dev/mmcblk0p7 bs=4M

        touch /tmp/oem.upgraded

        # switch on green led
	start-stop-daemon -S -q -b -x /usr/bin/blink.sh green

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

if [ $1 = "mount" ]; then 
        if df | awk '{ if ($6 == "/mnt/sdcard") { exit 1; } }'; then
                do_mount $2 $3
        else
                message "/mnt/sdcard is already mounted. no update will be made"
                exit 1
        fi

        IMG_FILE=$(find_update_image)
        if [[ -z ${IMG_FILE} ]]; then
                message "update is impossible"
                exit 1
        fi

        IMG_VERSION=$(echo $IMG_FILE | sed -n -E 's/VISION_OEM_//p' | sed -n -E 's/\.img//p')
        CUR_VERSION=$(cat /oem/etc/vision/version)

        message "doing update: ${CUR_VERSION} -> ${IMG_VERSION}"

        if ! do_upgrade /mnt/sdcard/${IMG_FILE}; then
                message "update failed"
                exit 1
        fi
        message "updated successfully with image ${IMG_FILE}"
elif [ $1 = "umount" ]; then
	message "umount"
        /bin/umount /mnt/sdcard
        [[ -e /tmp/oem.upgraded ]] && rm /tmp/oem.upgraded && reboot
else
        message "called with wrong parameter $1"
fi
