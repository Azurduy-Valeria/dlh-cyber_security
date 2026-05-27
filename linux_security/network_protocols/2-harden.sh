#!/bin/bash
find / -type d -perm -o+w 2>/dev/null | while read d; do printf '%s\n' "$d"; chmod o-w "$d"; done
