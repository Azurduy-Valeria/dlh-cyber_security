#!/bin/bash
whois $1 | awk '/^Registrant |^Admin |^Tech /{n=index($0,":");field=substr($0,1,n-1);value=substr($0,n+2);sub(/[[:space:]]*$/,"",value);if(field~/Ext/){sub(/\.?$/,":",field);print field","value}else if(field~/Street/){print field","value" "}else{print field","value}}' > $1.csv
