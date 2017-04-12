#!/usr/bin/env bash
sudo su
set -x

export DEBIAN_FRONTEND=noninteractive
export NODE=graphite-linode

echo "Making Base...." >&2
echo $NODE > /etc/hostname

echo hostname -F /etc/hostname
ip=$(ip addr show eth0 | grep -Po 'inet \K[\d.]+')
echo "$ip   $ip hostname" >> /etc/hosts
ln -sf /usr/share/zoneinfo/EST /etc/localtime

source /vagrant/scripts/graphite.sh