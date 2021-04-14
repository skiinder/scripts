#!/bin/bash
for ((i=70;i<80;i++));
do
    echo "192.168.5.$i	centos$i" >>/etc/hosts
done
