#!/bin/bash

openssl rsautl -sign -inkey vision_private.pem -passin file:pass_priv.txt -in "$1" -out "$1".secure
cat "$1".secure | base64 -w0 | qrencode -8 -o "$2" -t PNG