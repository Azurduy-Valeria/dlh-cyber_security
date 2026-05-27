#!/bin/bash
find / -xdev -type d -perm -0002 2>/dev/null | while read d; do printf '%s\n' "$d"; chmod o-w "$d"; done
