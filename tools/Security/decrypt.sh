#!/bin/bash

k=${3:-/tmp/vk}
k1=$(hexdump -e '/1 "%02x"' -n32 "$k")
k2=$(hexdump -e '/1 "%02x"' -s32 "$k")
openssl aes-256-cbc -d -K "$k1" -iv "$k2" -in "$1" -out "$2"
