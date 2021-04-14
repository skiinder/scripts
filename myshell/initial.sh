#!/bin/bash
read -p "Please input a username:" user
if [ $user ]
then
	useradd $user
	passwd $user
fi
read -p "Please input a machine number:" id
if [ -n $id ]; then id=70; fi

cat <<'EOF2' > /root/new
#!/bin/bash

if(($#==0)); then
    echo No args!;
    exit;
fi

if(($1<=2 || $1>255)); then
    echo Invalid args!;
    exit
fi

hostnamectl --static set-hostname centos$1

LAN=`ifconfig | grep broadcast | awk -F '.' '{print$3}'`

cat >/etc/sysconfig/network-scripts/ifcfg-ens33 <<EOF
TYPE="Ethernet"
BOOTPROTO="static"
NAME="ens33"
DEVICE="ens33"
ONBOOT="yes"
IPADDR="192.168.$LAN.$1"
PREFIX="24"
GATEWAY="192.168.$LAN.2"
DNS1="192.168.$LAN.2"
EOF

reboot
EOF2

chmod +x /root/new


yum install -y wget curl psmisc nc vim lrzsz rsync
yum update -y
systemctl disable firewalld
/root/new $id

