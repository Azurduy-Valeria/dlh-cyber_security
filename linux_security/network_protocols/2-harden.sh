#!/bin/bash
find / -type d -perm -o+w 2>/dev/null | while read d; do echo "$d"; chmod o-w "$d"; done
