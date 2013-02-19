#!/bin/bash

while true; do
        curl  http://localhost:8081/config-service -o /dev/null -s
        if [ $? -eq 0  ]; then
		if [ `curl  http://localhost:8081/config-service -o /dev/nul -s -w "%{http_code}"` -eq "200" ]; then
			exit 0
		fi
        fi      
	sleep 1
done;   
