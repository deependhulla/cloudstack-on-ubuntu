#!/bin/bash


hostipandsub=192.168.30.123/24
gateway=192.168.30.242
interface=enp1s0
DNS=8.8.8.8

apt-get -y  install bridge-utils openvswitch-switch ethtool net-tools

echo >  /etc/netplan/50-cloud-init.yaml
echo "network: {config: disabled}" > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
chmod 600  /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg


  cat << EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    $interface:
      dhcp4: false
      dhcp6: false
      optional: true
  bridges:
    cloudbr0:
      addresses: [$hostipandsub]
      routes:
        - to: default
          via: $gateway
      nameservers:
        addresses: [$DNS]
      interfaces: [$interface]
      dhcp4: false
      dhcp6: false
      parameters:
        stp: false
        forward-delay: 0
EOF


chmod 600  /etc/netplan/01-netcfg.yaml 

netplan generate
netplan apply

