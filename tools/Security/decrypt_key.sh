#!/bin/bash

[ -n "$2" ] || exit 1

rm -f "$2"
openssl rsautl -verify -inkey vision_public.pem -pubin -passin file:pass_pub.txt -in "$1" -out "$2"
