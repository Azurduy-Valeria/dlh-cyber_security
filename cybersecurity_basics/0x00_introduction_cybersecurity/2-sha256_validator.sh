#!/bin/bash
sha256sum "$1" | tee >(cut -d' ' -f1) | sha256sum -c -