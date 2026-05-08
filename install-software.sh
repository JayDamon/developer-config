#!/bin/bash

pacman -Syu
pacman -S docker docker-compose go jdk17-openjdk --noconfirm

### Configure Docker
systemctl start docker.service
usermod -aG docker $USER
