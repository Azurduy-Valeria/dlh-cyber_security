#!/bin/bash
ssh-keygen -lv -t rsa -b 4096 -f "$1"
