#!/bin/bash

rm -f *.pem *.key *.secure
openssl genrsa -aes256 -out vision_private.pem -passout file:pass_priv.txt 2048
openssl rsa -in vision_private.pem -passin file:pass_priv.txt -passout file:pass_pub.txt -pubout -out vision_public.pem
openssl rand 48 > vision.key
openssl rsautl -sign -inkey vision_private.pem -passin file:pass_priv.txt -in vision.key -out vision.secure
