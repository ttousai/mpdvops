#!/bin/bash

# Check for docker
d=$(which docker)
if [ ! -x "$d" ]; then
	apt-get update
	curl -fsSL https://get.docker.com -o get-docker.sh
	sudo sh get-docker.sh
	sudo usermod -aG docker ubuntu

fi

{
	cd /tmp/src
	sudo docker build -t mpdvops/app:latest .
	sudo docker stop app && sudo docker rm app
	sudo docker run -d --name app -p 0.0.0.0:5000:5000 mpdvops/app:latest
} > run.log
