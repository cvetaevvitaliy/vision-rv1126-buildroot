#!/bin/bash

[ "$#" -ne 2 ] && echo "$0 <key> <qr>"

cat "$1" | base64 -w0 | qrencode -8 -o "$2" -t PNG