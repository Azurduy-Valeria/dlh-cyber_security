#!/bin/bash
hash="${1#\{xor\}}"
for code in $(printf '%s' "$hash" | base64 -d | od -An -v -tu1)
do
    plain=$((code ^ 0x5f))
    printf "\\$(printf '%03o' "$plain")"
done
printf '\n'