#!/bin/bash
sha256sum "$1" | tee /dev/tty | sha256sum -c -