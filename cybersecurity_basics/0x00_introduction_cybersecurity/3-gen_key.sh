#!/bin/bash
ssh-keygen -N "" -t rsa -b 4096 -f "$1"
