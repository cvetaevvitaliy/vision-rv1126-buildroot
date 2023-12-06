#!/bin/bash

. /root/.bashrc.bak

# set -e # Abort on error

ROOT_PASSWD="123qwe"

NAME="vision"
DOMAIN_NAME="com"
HOST_NAME=${NAME}-board

cat /etc/os-release
uname -a

export DEBIAN_FRONTEND=noninteractive

echo "Configuring apt sources"

# cat - >/etc/apt/sources.list <<S2EOF
# deb http://ftp.uk.debian.org/debian/ buster main
# deb-src http://ftp.uk.debian.org/debian/ buster main

# deb http://security.debian.org/debian-security buster/updates main
# deb-src http://security.debian.org/debian-security buster/updates main

# # buster-updates, previously known as 'volatile'
# deb http://ftp.uk.debian.org/debian/ buster-updates main
# deb-src http://ftp.uk.debian.org/debian/ buster-updates main
# S2EOF

apt-get -y update
yes | unminimize
apt-get -y upgrade

echo "Setting timezone"
ln -fs /usr/share/zoneinfo/Europe/Kyiv /etc/localtime
apt-get install -y tzdata apt-utils
# This is necessary as tzdata will assume these are manually set and override the debconf values with their settings
dpkg-reconfigure --frontend noninteractive tzdata

echo "--------------------------------------------"

apt-get install -y sudo udev systemd ssh bash-completion kmod iproute2 ifupdown ethtool iputils-ping net-tools rsyslog dhcpcd5 bind9 \
    ufw incron htop vim nano util-linux libiio-dev iiod neofetch


# apt-get install -y sudo systemd autoconf bash-completion \
#     ssh build-essential kmod socat ifupdown ethtool iputils-ping net-tools rsyslog \
#     gcc g++ iproute2 iputils-ping dhcpcd5 incron udev systemd htop dialog \
#     vim cmake make util-linux apt-utils git strace gdb libiio-dev iiod neofetch

# apt-get install -y systemd sudo dialog bash-completion gcc build-essential cmake ifupdown net-tools apt-utils

echo "--------------------------------------------"

echo "Configuring networking"
echo "...lo"
cat - >>/etc/network/interfaces <<EOF

auto lo
iface lo inet loopback

allow-hotplug usb0
iface usb0 inet dhcp
pre-up ifconfig usb0 up
post-down ifconfig usb0 down
EOF


# echo "Configuring networking"
# firewall-cmd --add-port=43/tcp --permanent
# firewall-cmd --add-port=53/tcp --permanent
# firewall-cmd --reload
# echo "--------------------------------------------"


# echo "Configuring UFW Firewall"

echo "$HOST_NAME" > /etc/hostname

echo "Setting up "$HOST_NAME" to /etc/hosts"
cat - >/etc/hosts <<EOF
127.0.0.1       localhost
127.0.1.1       ${HOST_NAME}.${DOMAIN_NAME} ${HOST_NAME}

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

echo "--------------------------------------------"


echo "Enabling serial console"
systemctl enable serial-getty@ttyFIQ0.service

echo "--------------------------------------------"


echo "Setting root password"
echo "root:${ROOT_PASSWD}" | sudo chpasswd
echo "--------------------------------------------"

adduser ${NAME} --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password
echo "${NAME}:${ROOT_PASSWD}" | sudo chpasswd
adduser ${NAME} sudo --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password
usermod -aG sudo "${NAME}"



echo "add wellcome information"
. /etc/lsb-release
echo ${DISTRIB_DESCRIPTION}
echo "${DISTRIB_DESCRIPTION} " > /etc/issue
echo "Build: $(date +'%d/%m/%Y')" >> /etc/issue
echo ' ' >> /etc/issue
echo "login: ${NAME}" >> /etc/issue
echo "passw: ${ROOT_PASSWD}" >> /etc/issue
echo ' ' >> /etc/issue

echo "Update RC"

update-rc.d S60NPU_init defaults -f

update-rc.d S21mountall.sh defaults -f

update-rc.d S50usbdevice defaults -f

echo "--------------------------------------------"

echo "Update systemctl" 

systemctl enable S50usbdevice.service

systemctl enable S21mountall.sh.service

systemctl enable S60NPU_init.service

echo "--------------------------------------------"

echo "Tidying..."
apt-get clean


echo "=== STAGE 2 SUCCESSFULLY REACHED THE END ==="

sync

exit
