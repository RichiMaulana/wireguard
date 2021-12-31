#!/bin/bash

clear 

waktu=`date +%y%m%d%H%M%S`

echo -e "Ini adalah script auto untuk menambahkan klien wireguard"
echo ""
echo -n "Tekan enter untuk memulai"
read presskey
echo ""

echo -n "Masukkan nama klien. Misalkan client1, richi, etc. : "
read NamaKlien
sleep 3 
echo ""

echo -e "Sebelum memasukkan IP klien, pastikan IP tersebut belum dipakai"
echo ""
echo -e "Silakan cek file /etc/wireguard/peer.conf terlebih dahulu untuk memastikan"
echo ""
echo -n "Masukkan IP klien dengan ketentuan 10.100.10.x/32. (misal 10.100.10.102/32) : "
read IPKLIEN
sleep 3
echo ""

lokasibackup="/srv/backup"

echo -e "Membuat Folder Backup dan Backup Config"
echo ""
sleep 3

if [ ! -d $lokasibackup ]; then 
    mkdir -p $lokasibackup
fi

cp -rf /etc/wireguard /srv/backup/wg-bc-$waktu

echo -n "Membuat PrivateKey, PublicKey dan Peer pada Server. (Tekan Enter untuk memulai)"
read presskey 
echo ""
sleep 5

if [ ! -d /etc/wireguard/Secret ]; then 
    mkdir -p /etc/wireguard/Secret
fi

wg genkey | tee /etc/wireguard/Secret/$NamaKlien.key | wg pubkey > /etc/wireguard/Secret/$NamaKlien.pub

PrvKey=`cat /etc/wireguard/Secret/$NamaKlien.key`;
PubKey=`cat /etc/wireguard/Secret/$NamaKlien.pub`;

#### Perlu penyesuaian, simpan public key server di file /etc/wireguard/server.pub terlebih dahulu ####
SrvPubKey=`cat /etc/wireguard/server.pub`;

echo "
[Peer]
PublicKey = $PubKey
AllowedIPs = $IPKLIEN" >> /etc/wireguard/peer.conf


echo -e "Restart service Wireguard"
echo ""
sleep 3
systemctl restart wg-quick@wg0


echo -e "Membuat config file untuk klien"
echo ""

if [ ! -d /etc/wireguard/Client ]; then 
    mkdir -p /etc/wireguard/Client
fi

touch /etc/wireguard/Client/$NamaKlien.conf

echo "[Interface]
PrivateKey = $PrvKey
Address = $IPKLIEN
DNS = 1.1.1.1

[Peer]
PublicKey = $SrvPubKey
AllowedIPs = 0.0.0.0/0
Endpoint = 103.31.39.60:41194" > /etc/wireguard/Client/$NamaKlien.conf



echo -e "Pembuatan Klein Wireguard Sudah Selesai!"
echo ""
echo -e "Silakan cek file confignya di /etc/wireguard/Client/$NamaKlien.conf"
echo ""
read presskey