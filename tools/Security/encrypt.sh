#!/bin/bash

openssl aes-256-cbc -salt -K $(hexdump -e '/1 "%02x"' -n32 vision.key) -iv $(hexdump -e '/1 "%02x"' -s32 vision.key) -in "$1" -out "$2"
