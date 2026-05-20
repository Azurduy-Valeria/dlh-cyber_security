#!/bin/bash
printf "%s%s" "$1" "$(openssl rand -base64 12)" | openssl dgst -sha512 > 3_hash.txt
