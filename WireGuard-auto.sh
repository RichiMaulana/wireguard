#!/bin/bash

lokasi_backup=/srv/backup/wireguard
tanggal=`date +%y%m%H%M%S`
wg_dir=/etc/wireguard
wg_secret_dir=$wg_dir/secret
itisinstalled=`dpkg --list | grep wireguard`
srv_pub_key=`cat etc/wireguard/secret/server.pub`
IP_DEFAULT_SERVER=`hostname -I | cut -d " " -f 1`

clear

if [ ! -d $lokasi_backup ]
then
	mkdir -p $lokasi_backup
fi

wg_install()
{
	apt-get update -y # && apt upgrade -y
	apt-get install -y wireguard
}

wg_server_config()
{
	clear
	read -p "Nama Interface Wireguard (default: wg1): " wg_int
	read -p "IP Address Untuk Interface Wireguard (default: 10.10.10.1/24): " wg_srv_ip
	read -p "Port yang akan digunakan untuk Wireguard (default: 41194): " wg_srv_port

#### SET DEFAULT VALUE FOR WG_INT ####
	if [ -z $wg_int ];
	then 
		wg_int=wg1
	fi

#### SET DEFAULT VALUE FOR WG_SRV_PORT ####
	if [ -z $wg_srv_port ];
	then 
		wg_srv_port=41194
	fi

#### SET DEFAULT VALUE FOR WG_SRV_IP ####
	if [ -z $wg_srv_ip ];
	then 
		wg_srv_ip=10.10.10.1/24
	fi

	if [ -d $wg_dir ];
	then
		cp rf $wg_dir $lokasi_backup.$tanggal
	elif [ ! -d $wg_dir ]
	then 
		mkdir -m 0644 -p $wg_secret_dir
	fi
	
#	if [ ! -d $wg_secret_dir ]
#	then 
#		mkdir -m 0644 $-p wg_dir/$wg_secret_dir
#	fi

	wg genkey | sudo tee $wg_secret_dir/server.key | wg pubkey | sudo tee $wg_secret_dir/server.pub > /dev/null

	srv_priv_key=`cat /etc/wireguard/secret/server.key`

	touch $wg_dir/$wg_int.conf

	echo "[Interface]
Address = $wg_srv_ip
ListenPort = $wg_srv_port
PrivateKey = $srv_priv_key" > $wg_dir/$wg_int.conf
	
	systemctl start wg-quick@$wg_int
	systemctl enable wg-quick@$wg_int

}

wg_add_client()
{
	clear

	echo -n "Tekan enter untuk menambahkan klien"
	read presskey

	read -p "Nama interface Wireguard yang akan ditambah klien(Default: wg1): " wg_int

	read -p "Nama untuk klien (default: client1); " wg_client_name

	read -p "IP yang akan dijadikan endpoint untuk wireguard (Default ip lokal server kalian: $IP_DEFAULT_SERVER): " WG_ENDPOINT

	cat $wg_dir/$wg_int.conf | grep Address > /tmp/wg_ip.txt

	IP_WG_TO_PARSE=`tail -n 1 /tmp/wg_ip.txt | cut -d " " -f 3 | cut -d "." -f 4 |cut -d "/" -f 1`
	IP_BLOK4_PARSE=`expr $IP_WG_TO_PARSE + 1`
	IP_BLOK1=`tail -n 1 /tmp/wg_ip.txt | cut -d " " -f 3 | cut -d "." -f 1`
	IP_BLOK2=`tail -n 1 /tmp/wg_ip.txt | cut -d " " -f 3 | cut -d "." -f 2`
	IP_BLOK3=`tail -n 1 /tmp/wg_ip.txt | cut -d " " -f 3 | cut -d "." -f 3`
	SUBNET=`tail -n 1 /tmp/wg_ip.txt | cut -d " " -f 3 | cut -d "." -f 4 |cut -d "/" -f 2`
	WG_PORT=`cat /etc/wireguard/wg1.conf | grep Port | cut -d " " -f 3`
	
	if [ -z $wg_int ]
	then
		wg_int=wg1

	if [ -z WG_ENDPOINT ]
	then
		WG_ENDPOINT=$IP_DEFAULT_SERVER
	fi

	IP_KLIEN_USE=$IP_BLOK1.$IP_BLOK2.$IP_BLOK3.$IP_BLOK4_PARSE/$SUBNET

	echo -e "Sedang menambahkan klien $wg_wlient_name"

	wg genkey | sudo tee $wg_secret_dir/$wg_client_name.key | wg pubkey | sudo tee $wg_secret_dir/$wg_client_name.pub > /dev/null

	wg_client_key=`cat $wg_secret_dir/$wg_client_name.key`
	wg_client_pub=`cat $wg_secret_dir/$wg_client_name.pub`

	echo "
	[Peer]
	PublicKey = $wg_client_pub
	AllowedIPs = $IP_KLIEN_USE" >> $wg_dir/$wg_int.conf

}



echo -n 'Tekan enter untuk menginstall Wireguard'
read presskey
wg_install


echo -n 'Tekan enter untuk mengkonfigurasi Wireguard'
read presskey
wg_server_config

echo -e 'Done'

