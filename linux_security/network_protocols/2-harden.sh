#!/bin/bash
find / -xdev -type d -perm -0002 2>/dev/null -exec printf '%s\n' {} \; -exec chmod o-w {} +
