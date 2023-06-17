#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Hello World" > index.html
nohup busybox httpd -f -p ${server_port} &