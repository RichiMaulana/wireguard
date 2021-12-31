#!/bin/bash

lokasi_backup=/srv/backup/wireguard
tanggal=`date +%y%m%H%M%S`
wg_dir=/etc/wireguard
wg_secret_dir=$wg_dir/secret
itisinstalled=`dpkg --list | grep wireguard`
srv_pub_key=`cat /etc/wireguard/secret/server.pub`
IP_DEFAULT_SERVER=`hostname -I | cut -d " " -f 1`

##### HIASAN #####

function printc(){
  NC='\033[0m' # No Color

  case $1 in
    "green") COLOR='\033[0;32m' ;;
    "red") COLOR='\033[0;31m' ;;
    "*") COLOR='\033[0m' ;;
  esac

  echo -e "${COLOR} $2 ${NC}"
}

##### /HIASAN #####


if [ ! -d $lokasi_backup ]
then
	mkdir -p $lokasi_backup
fi

function g_install()
{
	apt-get update -y # && apt upgrade -y
	apt-get install -y wireguard
}

function wg_server_config()
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

#### Backup jika ada konfigurasi sebelumnya atau Buat directory Wireguard jika belum ada ####
	if [ -d $wg_dir ];
	then
		cp rf $wg_dir $lokasi_backup.$tanggal
	elif [ ! -d $wg_secret_dir ]
	then 
		mkdir -m 0644 -p $wg_secret_dir
	fi
	
#	if [ ! -d $wg_secret_dir ]
#	then 
#		mkdir -m 0644 $-p wg_dir/$wg_secret_dir
#	fi


#### Buat secret dan public key server ####
	wg genkey | sudo tee $wg_secret_dir/server.key | wg pubkey | sudo tee $wg_secret_dir/server.pub > /dev/null

	srv_priv_key=`cat /etc/wireguard/secret/server.key`

	touch $wg_dir/$wg_int.conf

	echo "[Interface]
Address = $wg_srv_ip
ListenPort = $wg_srv_port
PrivateKey = $srv_priv_key" > $wg_dir/$wg_int.conf
	
	systemctl start wg-quick@$wg_int
	systemctl enable wg-quick@$wg_int

	iptables -t nat -A PREROUTING -s $wg_ip 

}

function wg_add_client()
{
	srv_pub_key=`cat $wg_secret_dir/server.pub`

	echo -n "Tekan enter untuk menambahkan klien"
	read presskey

	read -p "Nama interface Wireguard yang akan ditambah klien(Default: wg1): " wg_int

	read -p "DNS yang akan digunakan. (Default: 1.1.1.1): " DNS

	if [ -z $wg_int ]
	then
		wg_int=wg1
	fi

	if [ -z $DNS ]
	then
		DNS=1.1.1.1
	fi

	read -p "Nama untuk klien (default: client1); " wg_client_name

	read -p "IP yang akan dijadikan endpoint untuk wireguard (Default ip lokal server kalian: $IP_DEFAULT_SERVER): " WG_ENDPOINT

	WG_IP_USED=`cat /etc/wireguard/wg1.conf | grep AllowedIPs | tail -n 1`

	if [ -z "$WG_IP_USED" ]
	then
		WG_IP_USED=`cat /etc/wireguard/wg1.conf | grep Address | tail -n 1`
	fi

	echo "$WG_IP_USED" > /tmp/wg_ip.txt

	IP_WG_TO_PARSE=`tail -n 1 /tmp/wg_ip.txt | cut -d " " -f 3 | cut -d "." -f 4 |cut -d "/" -f 1`
	IP_BLOK4_PARSE=`expr $IP_WG_TO_PARSE + 1`
	IP_BLOK1=`tail -n 1 /tmp/wg_ip.txt | cut -d " " -f 3 | cut -d "." -f 1`
	IP_BLOK2=`tail -n 1 /tmp/wg_ip.txt | cut -d " " -f 3 | cut -d "." -f 2`
	IP_BLOK3=`tail -n 1 /tmp/wg_ip.txt | cut -d " " -f 3 | cut -d "." -f 3`
	SUBNET=`tail -n 1 /tmp/wg_ip.txt | cut -d " " -f 3 | cut -d "." -f 4 |cut -d "/" -f 2`
	WG_PORT=`cat $wg_dir/$wg_int.conf | grep Port | cut -d " " -f 3`

	IP_KLIEN_USE=$IP_BLOK1.$IP_BLOK2.$IP_BLOK3.$IP_BLOK4_PARSE/$SUBNET


	if [ -z $wg_client_name ]
	then
		wg_client_name=client1
	fi

	if [ -z $WG_ENDPOINT ]
	then
		WG_ENDPOINT=$IP_DEFAULT_SERVER
	fi

	cp -rf /etc/wireguard $lokasi_backup/$waktu

	echo -e "Sedang menambahkan klien $wg_client_name"

	wg genkey | sudo tee $wg_secret_dir/$wg_client_name.key | wg pubkey | sudo tee $wg_secret_dir/$wg_client_name.pub > /dev/null

	wg_client_key=`cat $wg_secret_dir/$wg_client_name.key`
	wg_client_pub=`cat $wg_secret_dir/$wg_client_name.pub`

	if [ ! -d $wg_dir/client ]
	then
		mkdir -p $wg_dir/client
	fi

	wg_client_dir=/etc/wireguard/client
	wg_port=`cat $wg_dir/$wg_int.conf | grep Port | cut -d " " -f3`

	echo "
[Peer]
PublicKey = $wg_client_pub
AllowedIPs = $IP_KLIEN_USE" >> $wg_dir/$wg_int.conf

	echo "[Interface]
PrivateKey = $wg_client_key
Address = $IP_KLIEN_USE
DNS = $DNS

[Peer]
PublicKey = $srv_pub_key
AllowedIPs = 0.0.0.0/0
Endpoint = $IP_DEFAULT_SERVER:$wg_port" > $wg_client_dir/$wg_client_name.conf

	rm /tmp/wg_ip.txt
	systemctl restart wg-quick@$wg_int

	echo -e "DONE"

}


clear
echo -e "Hai, ini adalah script auto yang bisa install, konfigurasi dan tambah klien wireguard secara otomatis!"
echo -e ""
echo -e "Silakan pilih apa yang akan kamu lakukan: 
1. Install Wireguard
2. Tambah Klien
3. Batalkan"
#read -p "Ketik 1, 2 atau 3 lalu enter untuk melanjutkan: " pilihan1

while :
do
	read -p "Ketik 1, 2 atau 3 lalu enter untuk melanjutkan: " pilihan1
	case $pilihan1 in
		1)
			wg_install
			wg_server_config
			break
			;;
		[Ii]nstall)
			wg_install
			wg_server_config
			break
			;;
		2)
			wg_add_client
			break
			;;
		3)
			break
			;;
		*)
			echo -e "Maaf, pilihan kamu salah"
			;;
	esac
done