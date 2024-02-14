#!/bin/bash

mode=1
if [ -z $2 ]; then
	mode=0
fi

while [ 1 = 1 ]; do
	echo 1 > /sys/devices/platform/leds/leds/$1/brightness
	sleep 1

	echo $mode > /sys/devices/platform/leds/leds/$1/brightness
	sleep 1
done

