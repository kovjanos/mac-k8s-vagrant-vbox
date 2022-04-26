#!/bin/bash

export DEBIAN_FRONTEND=noninteractive 

apt-get -y -qq -o Dpkg::Use-Pty=false install  \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common 

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | tee /etc/apt/trusted.gpg.d/docker.asc > docker.pgp.error
add-apt-repository \
    "deb https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
     $(lsb_release -cs) \
     stable"

apt-get update -qq  
apt-get install -y -qq -o=Dpkg::Use-Pty=0 docker-ce=$(apt-cache madison docker-ce | grep 20.10 | head -1 | awk '{print $3}')
