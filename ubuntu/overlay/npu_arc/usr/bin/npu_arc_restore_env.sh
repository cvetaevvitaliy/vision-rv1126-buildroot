#!/bin/sh

printf "rmmod the NPU modules with version 1.6.0"
killall start_rknn.sh > /dev/null 2>&1
killall rknn_server > /dev/null 2>&1
rmmod galcore
printf "insmod the NPU modules:"
cp /usr/lib/cl_*.h /tmp/
insmod /lib/modules/galcore.ko contiguousSize=0x400000
unset MAX_FREQ
read  MAX_FREQ < /sys/class/devfreq/ffbc0000.npu/max_freq
echo  $MAX_FREQ > /sys/class/devfreq/ffbc0000.npu/userspace/set_freq
[ $? = 0 ] && echo "OK" || echo "FAIL"
start_rknn.sh &
sleep 0.5
