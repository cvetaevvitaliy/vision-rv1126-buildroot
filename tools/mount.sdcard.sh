#!/bin/bash
# this script should be run by 61-sd-cards-auto-mount.rules

message() {
        logger -s "mount.sdcard.sh: $1"
}

find_update_image() {
        TEMPLATE=".*VISION_OEM_([[:digit:]]{1,3}\.){3}img"

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

compare_versions() {
        IMAGE_VERSION=$2 #$(echo $1 | sed -n -E 's/VISION_OEM_//p' | sed -n -E 's/\.img//p')
        INSTALLED=$1 #$(echo /oem/etc/vision/version)
        message "compare_versions: ${IMAGE_VERSION} : ${INSTALLED}"

        # extract versions' components
        IMG_MAJ=$(echo $IMAGE_VERSION | awk -F . '{ print $1 }')
        IMG_MID=$(echo $IMAGE_VERSION | awk -F . '{ print $2 }')
        IMG_MIN=$(echo $IMAGE_VERSION | awk -F . '{ print $3 }')

        INST_MAJ=$(echo $INSTALLED | awk -F . '{ print $1 }')
        INST_MID=$(echo $INSTALLED | awk -F . '{ print $2 }')
        INST_MIN=$(echo $INSTALLED | awk -F . '{ print $3 }')

        if [ $INST_MAJ -gt $IMG_MAJ ]; then
                return 2 
        elif [ $INST_MAJ -lt $IMG_MAJ ]; then
                return 1
        elif [ $INST_MID -gt $IMG_MID ]; then
                return 2
        elif [ $INST_MID -lt $IMG_MID ]; then
                return 1
        elif [ $INST_MIN -gt $IMG_MIN ]; then
                return 2
        elif [ $INST_MIN -lt $IMG_MIN ]; then
                return 1
        fi

        return 0
}


blink() {
        # ${1} color
        while [ 1 == 1 ]; do
                echo 1 > /sys/devices/platform/leds/leds/${1}/brightness
                sleep 1
                echo 0 > /sys/devices/platform/leds/leds/${1}/brightness
                sleep 1
        done
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

        message "backing up existing /oem"
        dd if=/dev/mmcblk0p7 of=/userdata/current.oem bs=4M
        message "updating /oem"
        dd if=$UPDATE_IMG_FILE of=/dev/mmcblk0p7 bs=4M

        blink green&
	# should check if partition was written successfully
        # if ! /oem/usr/bin/sanity_check.sh; then
        #         message "restoring backed up"
        #         /oem/usr/bin/vision stop
        #         sleep 5 # let the processes stop
        #         umount /oem
        #         dd of=/dev/mmcblk0p7 if=/userdata/current.oem bs=4M
        #         mount /dev/mmcblk0p7 /oem
        #         /oem/usr/bin/vision start
        #         exit 1
        # fi
        message "updated services, exiting normally"
        exit 0
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
        touch /tmp/oem.upgraded
        message "updated successfully with image ${IMG_FILE}"
elif [ $1 = "umount" ]; then
        /bin/umount /mnt/sdcard
        [[ -e /tmp/oem.upgraded ]] && rm /tmp/oem.upgraded && reboot
else
        message "called with wrong parameter $1"
fi



