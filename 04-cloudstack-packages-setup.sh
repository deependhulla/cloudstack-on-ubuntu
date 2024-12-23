#!/bin/bash

CS_VERSION=4.20
U_VERSION=jammy

mkdir -p /etc/apt/keyrings
wget -O- https://download.cloudstack.org/release.asc 2>/dev/null | gpg --dearmor | sudo tee /etc/apt/keyrings/cloudstack.gpg > /dev/null
echo deb [signed-by=/etc/apt/keyrings/cloudstack.gpg] https://download.cloudstack.org/ubuntu $U_VERSION $CS_VERSION > /etc/apt/sources.list.d/cloudstack.list

apt-get update

