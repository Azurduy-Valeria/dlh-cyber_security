#!/bin/bash
length="$1"
tr -dc '[:alnum:]' < /dev/urandom | head -c "$length"; echo