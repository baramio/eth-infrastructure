#!/bin/bash

adduser eth
usermod -aG sudo eth
sudo usermod -aG docker eth
newgrp docker
sudo apt remove --purge --assume-yes snapd
sudo apt update && sudo apt -y dist-upgrade
sudo apt install -y docker-compose
sudo systemctl enable --now docker
sudo timedatectl set-ntp no
sudo apt-get -y install chrony
sudo systemctl start chronyd
sudo systemctl enable chronyd


sudo apt-get install ufw
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 30303/tcp
sudo allow 30303/udp
sudo ufw allow 30303/udp
sudo ufw allow 9000/tcp
sudo ufw allow 9000/udp
sudo ufw allow out 53/tcp
sudo ufw allow out 53/udp
sudo ufw allow out http
sudo ufw allow out https
sudo ufw allow out 7844/tcp
sudo ufw allow out 7844/udp
sudo ufw allow out 30303/tcp
sudo ufw allow out 30303/udp
sudo ufw allow out 123/udp
sudo ufw allow in 123/udp
sudo ufw allow out 9000/tcp
sudo ufw allow out 9000/udp
sudo ufw default reject outgoing
sudo ufw status verbose


mkdir /home/eth/ec
mkdir /home/eth/cc
mkdir /home/eth/ec/goerli
mkdir /home/eth/cc/goerli
docker network create -d bridge goerli-network