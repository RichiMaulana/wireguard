#!/bin/bash

# Add Klien

cat /etc/wireguard/wg1.conf | grep Address > /tmp/wg_ip.txt

IP_WG_TO_PARSE=`tail -n 1 /tmp/wg_ip.txt | cut -d " " -f 3 | cut -d "." -f 4 |cut -d "/" -f 1`
IP_BLOK4_PARSE=`expr $IP_WG_TO_PARSE + 1`
IP_BLOK1=`tail -n 1 /tmp/wg_ip.txt | cut -d " " -f 3 | cut -d "." -f 1`
IP_BLOK2=`tail -n 1 /tmp/wg_ip.txt | cut -d " " -f 3 | cut -d "." -f 2`
IP_BLOK3=`tail -n 1 /tmp/wg_ip.txt | cut -d " " -f 3 | cut -d "." -f 3`
SUBNET=`tail -n 1 /tmp/wg_ip.txt | cut -d " " -f 3 | cut -d "." -f 4 |cut -d "/" -f 2`

IP_KLIEN_USE=$IP_BLOK1.$IP_BLOK2.$IP_BLOK3.$IP_BLOK4_PARSE/$SUBNET

echo $IP_WG_TO_PARSE
echo $IP_BLOK1
echo $IP_BLOK3
echo $IP_BLOK2
echo $IP_KLIEN_USE