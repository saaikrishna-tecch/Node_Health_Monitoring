#!/bin/bash

set -euo pipefail

sudo apt install nginx docker.io -y
sudo systemctl start nginx
sudo systemctl start docker

docker run -d --name my-app -p 8080:80 nginx
