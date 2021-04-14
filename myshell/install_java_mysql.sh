#!/bin/bash
#JAVA
ls jdk*.rpm | xargs rpm -ivh
jdk=/usr/java/`ls /usr/java | grep jdk`
cat >>/etc/profile <<EOF
#JAVA_HOME
JAVA_HOME=$jdk
EOF

rpm -Uvh https://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm
sed -i '/MySQL 8\.0 Community Server/,/enabled=1/{s/enabled=1/enabled=0/}' mysql-community.repo
sed -i '/MySQL 5\.5 Community Server/,/enabled=0/{s/enabled=0/enabled=1/}' mysql-community.repo
yum install -y mysql-server

