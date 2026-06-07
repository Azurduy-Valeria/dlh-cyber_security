#!/bin/bash
sudo nmap -sS -sn -p22,80,443 $1
