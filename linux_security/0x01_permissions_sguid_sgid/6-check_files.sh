#!/bin/bash

# Find all files modified in the last 24 hours with SUID or SGID set
# and list detailed information about those files

# Check if directory argument is provided
if [ -z "$1" ]; then
	echo "Usage: $0 <directory>"
	exit 1
fi

# Check if directory exists
if [ ! -d "$1" ]; then
	echo "Error: Directory '$1' does not exist"
	exit 1
fi

# Find files with SUID or SGID modified in last 24 hours and list them
find "$1" -type f -mtime -1 \( -perm -4000 -o -perm -2000 \) -exec ls -l {} \;
