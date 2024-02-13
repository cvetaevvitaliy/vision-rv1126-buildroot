#!/bin/bash

while [ 1 = 1 ]; do
	echo 1 > /sys/devices/platform/leds/leds/green/brightness
	sleep 1

	echo 0 > /sys/devices/platform/leds/leds/green/brightness
	sleep 1
done

