#!/bin/sh

export RKNN_SERVER_PLUGINS='/npu_arc/usr/lib/npu/rknn/plugins/'

while true
do
  sleep 1
  /npu_arc/usr/bin/rknn_server #>/dev/null 2>&1
done
