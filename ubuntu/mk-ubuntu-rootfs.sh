#!/bin/bash
IFS=$'\n\t'
COMMON_DIR=$(cd `dirname $0`; pwd)
KERNEL_MODULES=${COMMON_DIR}/../deploy/modules

UBUNTU_ROOTFS_LINK="https://cdimage.ubuntu.com/ubuntu-base/releases/20.04.5/release"
ROOTFS_NAME="ubuntu-base-20.04.2-base-armhf.tar.gz"
IMAGE_FILENAME="rootfs.img"

MOUNT_PATH="/tmp/ubuntu_rootfs"

SUDO_ASKPASS=password.sh


# if [ -h $0 ]
# then
#         CMD=$(readlink $0)
#         COMMON_DIR=$(dirname $CMD)
# fi



download_rootfs() {


        echo " download to "${COMMON_DIR}/dl/${ROOTFS_NAME}""
        mkdir -p ${COMMON_DIR}/dl
        if [ -f "${COMMON_DIR}/dl/${ROOTFS_NAME}" ] ; then
                echo "File downloaded: ${COMMON_DIR}/${ROOTFS_NAME}"
        #exit 0 ;
        else 
                wget -P "${COMMON_DIR}/dl/" "${UBUNTU_ROOTFS_LINK}/${ROOTFS_NAME}" || { exit 1 ; }
        fi

}


create_rootfs() {

        if ! [ -f "${COMMON_DIR}/${IMAGE_FILENAME}" ]; then
                echo "Create ${IMAGE_FILENAME}"
                dd if=/dev/zero of="${COMMON_DIR}/${IMAGE_FILENAME}" bs=2048M count=1 status=progress || { exit 1 ; }
                	
                mkfs.ext4 "${COMMON_DIR}/${IMAGE_FILENAME}"
                tune2fs -c0 -i0 "${COMMON_DIR}/${IMAGE_FILENAME}"
                echo "Done ..."
           
        else
                echo "Found image ${COMMON_DIR}/${IMAGE_FILENAME}"
                echo ""
        fi

}

unpack_rootfs() {
        echo "unpack rootfs..."
        sudo -S mkdir -p ${MOUNT_PATH}
        sudo -S mount ${COMMON_DIR}/${IMAGE_FILENAME} ${MOUNT_PATH}

        sudo -S tar xzpf "${COMMON_DIR}/dl/${ROOTFS_NAME}" -C ${MOUNT_PATH} || { exit 1 ; }
        sync
        case "$?" in
                0) echo "Sync OK"  ;;
                *) echo "Error sync " ;;
        esac
}

umount_rootfs() {
        echo umount
        sudo -S umount ${MOUNT_PATH}
}


prepare_distributive() {

        if ! [ -x "$(command -v qemu-aarch64-static)" ]; then
                echo 'Error: qemu-user-static is not installed.' >&2
                echo "sudo apt-get install qemu-user-static"
                exit 1
        fi

        sudo -S cp -b /etc/resolv.conf ${MOUNT_PATH}/etc/resolv.conf

        sudo -S cp /usr/bin/qemu-aarch64-static ${MOUNT_PATH}/usr/bin/

        echo "Mounting proc, dev and sys"
        sudo -S mount -o bind,ro /dev ${MOUNT_PATH}/dev
        sudo -S mount -o bind,ro /dev/pts ${MOUNT_PATH}/dev/pts
        sudo -S mount -t proc none ${MOUNT_PATH}/proc
        sudo -S mount -t sysfs none ${MOUNT_PATH}/sys

        echo "Copy overlay FS"
        sudo -S cp -r ${COMMON_DIR}/overlay/* ${MOUNT_PATH}/

        echo "Kernel modules"
        sudo -S cp -r ${KERNEL_MODULES}/lib/* ${MOUNT_PATH}/usr/lib/

        if [ -a ${MOUNT_PATH}/root/.bashrc ]; then
                echo "Create backup .bashrc"
                sudo -S cp ${MOUNT_PATH}/root/.bashrc ${MOUNT_PATH}/root/bashrc.bak
        fi

        sudo -S cp ${COMMON_DIR}/stage-2-setup.bash ${MOUNT_PATH}/root/.bashrc

        sudo -S chroot ${MOUNT_PATH}/

        sudo -S rm ${MOUNT_PATH}/root/.bashrc

        echo "Removing stage 2 script"
        if [ -a ${MOUNT_PATH}/root/bashrc.bak ]; then
                echo "Restore backup .bashrc"
                sudo -S mv ${MOUNT_PATH}/root/bashrc.bak ${MOUNT_PATH}/root/.bashrc
        fi

        sync

        sudo -S umount ${MOUNT_PATH}/dev/pts
        sudo -S umount ${MOUNT_PATH}/dev
        sudo -S umount ${MOUNT_PATH}/proc
        sudo -S umount ${MOUNT_PATH}/sys

}


download_rootfs

create_rootfs

unpack_rootfs

prepare_distributive

