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
	# Start flask app
	cd /tmp/src
	sudo docker build -t mpdvops/app:latest .
	sudo docker stop app && sudo docker rm app
	sudo docker run -d --name app mpdvops/app:latest

	# Start NGINX
	sudo docker rm nginx
	sudo docker run \
 	  --name nginx \
  	  --link app \
  	  --detach \
  	  --publish 80:80 \
  	  --mount type=bind,source=$(pwd)/nginx.conf,target=/etc/nginx/nginx.conf \
  	  nginx:1.13-alpine
} > run.log
