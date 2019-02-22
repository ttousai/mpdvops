#!/bin/bash

sudo docker build -t mpdvops/app:latest .
sudo docker run -d --name app -p 0.0.0.0:5000:5000 mpdvops/app:latest
