#!/bin/bash

# Script to display the last 5 login sessions for users with dates and times
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo privileges"
   exit 1
fi

last -5