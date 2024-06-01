#!/bin/bash

[ -z "$1" ] && { echo "$0 <filename>"; exit 1; }

old_pwd=$PWD
cd /oem/assets

k=${2:-/tmp/vk}
rm -f "$k"
openssl rsautl -verify -inkey vision_public.pem -pubin -passin file:pass_pub.txt -in "$1" -out "$k" || exit 1

if [ "$(cat "$k")" == '{"cmd":"reboot bootloader"}' ]; then
    logger -t "$0" "reboot bootloader"
    reboot bootloader
    exit 0
fi

k1=$(hexdump -v -e '/1 "%02x"' -n32 "$k")
k2=$(hexdump -v -e '/1 "%02x"' -s32 "$k")

TAR_FN="/tmp/vs.tar.gz"
openssl aes-256-cbc -d -K "$k1" -iv "$k2" -in "/oem/assets/vs.bin" -out "$TAR_FN" || exit 2

cd /
tar xzvf "$TAR_FN" . || exit 3

INIT_PATH=/tmp/vision_security/etc/init.d

for scr in $(ls -1 -v ${INIT_PATH}/S* ); do 
    [ -x "$scr" ] && { echo "Start $scr"; "$scr" start; }
done

cd "$old_pwd"

exit 0