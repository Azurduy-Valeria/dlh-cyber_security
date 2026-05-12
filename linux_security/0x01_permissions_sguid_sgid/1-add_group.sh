#!/bin/bash
addgroup $1
chown ${SUDO_USER}:$1 $2
chmod g+rx $2