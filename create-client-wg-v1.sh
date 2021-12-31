#!/bin/bash

backup_lokasi=/srv/backup/wireguard
tanggal=`date +%y%m%H%M%S`
wg_dir=/etc/wireguard
wg_secret_dir=$wg_dir/secret
itisinstalled=`dpkg --list | grep wireguard`

apt install wireguard

if [ ! -d /etc/wireguard/secret ]
then
    mkdir -p /etc/wireguard/secret
fi

if [ ! -d $backup_lokasi ]
then
    mkdir -p $backup_lokasi
fi

wg genkey | sudo tee /etc/wireguard/secret/server.key | wg pubkey | sudo tee /etc/wireguard/secret/server.pub

read -p "Nama Interface Wireguard: " wg_int
read -p "IP Address Untuk Interface Wireguard (misal: 10.10.10.10): " wg_ip
wg_conf=$wg_dir/$wg_int

PrivateKey=`cat $wg_secret_dir/server.key`
PublicKey=`cat $wg_secret_dir/server.pub`

touch $wg_dir/$wg_int

echo "[Interface]
Address = $wg_ip/24
ListenPort = 41194
PrivateKey = $PrivateKey
" > $wg_dir/$wg_int
 