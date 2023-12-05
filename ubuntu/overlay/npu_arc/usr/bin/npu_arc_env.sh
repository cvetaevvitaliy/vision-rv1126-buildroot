#!/bin/sh

export LD_LIBRARY_PATH=/npu_arc/usr/lib/npu/rknn:/npu_arc/usr/lib/:/npu_arc/usr/lib/npu/rknn/plugins/:$LD_LIBRARY_PATH
export PATH=/npu_arc/usr/bin/:$PATH

galcore_version=$(dmesg | grep "Galcore version" | awk 'END {print}' | awk -F ' ' '{print $5}')
if [ $galcore_version = "6.4.3.5.293908" ]; then
    echo "NPU version already is 1.6.0"
else
    printf "rmmod NPU modules: "
    killall start_rknn.sh > /dev/null 2>&1
    killall rknn_server > /dev/null 2>&1
    rmmod galcore
    printf "insmod the NPU modules with version 1.6.0"
    cp /npu_arc/usr/lib/cl_*.h /tmp/
    insmod /npu_arc/lib/modules/galcore.ko contiguousSize=0x400000 gpuProfiler=1
    unset MAX_FREQ
    read  MAX_FREQ < /sys/class/devfreq/ffbc0000.npu/max_freq
    echo  $MAX_FREQ > /sys/class/devfreq/ffbc0000.npu/userspace/set_freq
    [ $? = 0 ] && echo "OK" || echo "FAIL"
    /npu_arc/usr/bin/start_rknn.sh &
    sleep 0.5
fi
