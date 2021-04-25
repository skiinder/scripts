#!/bin/bash

ENV_FILE=/etc/profile.d/my_env.sh
USR=atguigu
OSS="http://hadoop3.oss-cn-zhangjiakou-internal.aliyuncs.com"
export CLUSTER="hadoop102 hadoop103 hadoop104"

function prt() 
{
  echo ">>>>>>>>  $1  <<<<<<<<"
}
function init_env() {
prt "初始化环境变量"
[ -f $ENV_FILE ] || touch $ENV_FILE
sed -i "/CLUSTER/d" $ENV_FILE
cat >> $ENV_FILE << EOF
#CLUSTER
export CLUSTER="$CLUSTER"
EOF
xsync $ENV_FILE
prt "安装必要依赖"
xcall "yum install -y epel-release" >/dev/null 2>&1
xcall "yum install -y psmisc nc net-tools zip unzip rsync vim lrzsz ntp libzstd openssl-static tree iotop libaio pv pdsh" >/dev/null 2>&1
}

function add_site() {
if [ ! -e $1 ]; then
touch $1
cat > $1 << EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
</configuration>
EOF
fi
  sed -i "/<name>$2<\/name>/d" $1
  sed -i "/<\/configuration>/i<property><name>$2<\/name><value>$3<\/value><\/property>" $1
}

function add_property() {
if [ ! -e $1 ]; then
touch $1
fi
sed -i "/$2/d" $1
echo "$2=$3" >> $1
}

function install_package() {
  curl -s $OSS/$1 | pv | tar zxC /opt/module
}

function depend_on() {
  for i in $@; do
    case $i in
    "env")
      su - atguigu -c "which pv >/dev/null 2>&1" || init_env $CLUSTER
      ;;
    "java"|"mysql")
      su - atguigu -c "which $i >/dev/null 2>&1" || init_$i $CLUSTER
      ;;
    "hadoop"|"zookeeper"|"hive"|"kafka"|"flume"|"sqoop"|"hbase"|"spark"|"azkaban"|"presto"|"kylin")
      test -d /opt/module/$i || init_$i $CLUSTER
      ;;
    *)
      echo "$i not supported yet"
    esac
  done
}
function init_java() {
prt "正在初始化JAVA"
depend_on env
[ -z "$JAVA_HOME" ] && JAVA_HOME=/opt/module/jdk1.8.0_212
xcall "rm -rf $JAVA_HOME"
install_package jdk-8u212-linux-x64.tar.gz
xsync $JAVA_HOME
sed -i "/JAVA_HOME/d" $ENV_FILE
cat >>  $ENV_FILE << EOF
#JAVA_HOME
export JAVA_HOME=$JAVA_HOME
export PATH=\$PATH:\$JAVA_HOME/bin
EOF
xsync $ENV_FILE
}

function init_hadoop() {
depend_on java
NN=$1
RM=$2
SNN=$3
prt "正在初始化HADOOP"
[ -z "$HADOOP_HOME" ] && HADOOP_HOME=/opt/module/hadoop
xcall "rm -rf $HADOOP_HOME"
install_package hadoop-3.1.3.tar.gz
mv /opt/module/hadoop-3.1.3 $HADOOP_HOME
xsync $HADOOP_HOME

add_site $HADOOP_HOME/etc/hadoop/core-site.xml "fs.defaultFS" "hdfs://$NN:8020"
add_site $HADOOP_HOME/etc/hadoop/core-site.xml "hadoop.tmp.dir" "$HADOOP_HOME/data"
add_site $HADOOP_HOME/etc/hadoop/core-site.xml "hadoop.proxyuser.$USR.hosts" "*"
add_site $HADOOP_HOME/etc/hadoop/core-site.xml "hadoop.proxyuser.$USR.groups" "*"
add_site $HADOOP_HOME/etc/hadoop/core-site.xml "hadoop.http.staticuser.user" "$USR"

add_site $HADOOP_HOME/etc/hadoop/hdfs-site.xml "dfs.namenode.secondary.http-address" "$SNN:9868"
add_site $HADOOP_HOME/etc/hadoop/hdfs-site.xml "dfs.hosts.exclude" "$HADOOP_HOME/etc/hadoop/blacklist"
add_site $HADOOP_HOME/etc/hadoop/hdfs-site.xml "dfs.hosts" "$HADOOP_HOME/etc/hadoop/workers"

add_site $HADOOP_HOME/etc/hadoop/mapred-site.xml "mapreduce.framework.name" "yarn"
add_site $HADOOP_HOME/etc/hadoop/mapred-site.xml "mapreduce.jobhistory.address" "$SNN:10020"
add_site $HADOOP_HOME/etc/hadoop/mapred-site.xml "mapreduce.jobhistory.webapp.address" "$SNN:19888"

add_site $HADOOP_HOME/etc/hadoop/yarn-site.xml "yarn.nodemanager.aux-services" "mapreduce_shuffle"
add_site $HADOOP_HOME/etc/hadoop/yarn-site.xml "yarn.resourcemanager.hostname" "$RM"
add_site $HADOOP_HOME/etc/hadoop/yarn-site.xml "yarn.nodemanager.env-whitelist" "JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_MAPRED_HOME"
add_site $HADOOP_HOME/etc/hadoop/yarn-site.xml "yarn.scheduler.minimum-allocation-mb" "512"
add_site $HADOOP_HOME/etc/hadoop/yarn-site.xml "yarn.scheduler.maximum-allocation-mb" "8192"
add_site $HADOOP_HOME/etc/hadoop/yarn-site.xml "yarn.nodemanager.resource.memory-mb" "8192"
add_site $HADOOP_HOME/etc/hadoop/yarn-site.xml "yarn.nodemanager.pmem-check-enabled" "false"
add_site $HADOOP_HOME/etc/hadoop/yarn-site.xml "yarn.nodemanager.vmem-check-enabled" "false"
add_site $HADOOP_HOME/etc/hadoop/yarn-site.xml "yarn.log-aggregation-enable" "true"
add_site $HADOOP_HOME/etc/hadoop/yarn-site.xml "yarn.log.server.url" "http://\${yarn.timeline-service.webapp.address}/applicationhistory/logs"
add_site $HADOOP_HOME/etc/hadoop/yarn-site.xml "yarn.log-aggregation.retain-seconds" "604800"
add_site $HADOOP_HOME/etc/hadoop/yarn-site.xml "yarn.timeline-service.enabled" "true"
add_site $HADOOP_HOME/etc/hadoop/yarn-site.xml "yarn.timeline-service.hostname" "\${yarn.resourcemanager.hostname}"
add_site $HADOOP_HOME/etc/hadoop/yarn-site.xml "yarn.timeline-service.http-cross-origin.enabled" "true"
add_site $HADOOP_HOME/etc/hadoop/yarn-site.xml "yarn.resourcemanager.system-metrics-publisher.enabled" "true"

touch $HADOOP_HOME/etc/hadoop/blacklist
sed -i '/maximum-am-resource-percent/,/\/value/s/0\.1/0.5/' $HADOOP_HOME/etc/hadoop/capacity-scheduler.xml
cat > $HADOOP_HOME/etc/hadoop/workers << EOF
$1
$2
$3
EOF
xsync $HADOOP_HOME/etc
sed -i "/HADOOP_HOME/d" $ENV_FILE
cat >>  $ENV_FILE << EOF
#HADOOP_HOME
export HADOOP_HOME=$HADOOP_HOME
export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin
EOF
xsync $ENV_FILE

prt "正在格式化Namenode"
su - $USR -c "hdfs namenode -format 1>/dev/null 2>&1 &" 
} 

function init_zookeeper() {
depend_on java
prt "正在初始化Zookeeper"
[ -z "$ZOOKEEPER_HOME" ] && ZOOKEEPER_HOME=/opt/module/zookeeper
xcall "rm -rf $ZOOKEEPER_HOME"
install_package apache-zookeeper-3.5.7-bin.tar.gz
mv /opt/module/apache-zookeeper-3.5.7-bin $ZOOKEEPER_HOME
xsync $ZOOKEEPER_HOME

touch $ZOOKEEPER_HOME/conf/zoo.cfg
cat > $ZOOKEEPER_HOME/conf/zoo.cfg << EOF
tickTime=2000
initLimit=10
syncLimit=5
dataDir=$ZOOKEEPER_HOME/zkData
clientPort=2181
admin.serverPort=8085
server.${1: -1}=$1:2888:3888
server.${2: -1}=$2:2888:3888
server.${3: -1}=$3:2888:3888
EOF
xsync $ZOOKEEPER_HOME/conf/zoo.cfg

xcall "mkdir -p $ZOOKEEPER_HOME/zkData"
xcall "HOST=\$(hostname);echo \${HOST: -1} > $ZOOKEEPER_HOME/zkData/myid"

sed -i "/ZOOKEEPER_HOME/d" $ENV_FILE
cat >>  $ENV_FILE << EOF
#ZOOKEEPER_HOME
export ZOOKEEPER_HOME=$ZOOKEEPER_HOME
export PATH=\$PATH:\$ZOOKEEPER_HOME/bin
EOF
xsync $ENV_FILE
prt "正在生成控制脚本zkS.sh"
cat <<'EOF'> $ZOOKEEPER_HOME/bin/zkS.sh
#!/bin/bash
xcall "zkServer.sh $@" 2>/dev/null | grep -v Client
EOF
chown $USR:$USR $ZOOKEEPER_HOME/bin/zkS.sh
chmod +x $ZOOKEEPER_HOME/bin/zkS.sh
}

function init_mysql(){
MYSQL=$(hostname)
prt "正在停止并卸载MySQL"
service mysql stop 2>/dev/null
service mysqld stop 2>/dev/null
rpm -qa | grep -i -E mysql\|mariadb | xargs -n1 rpm -e --nodeps
rm -rf /var/lib/mysql
rm -rf /usr/lib64/mysql
rm -rf /etc/my.cnf
rm -rf /usr/my.cnf
rm -rf /var/log/mysqld.log
prt "正在安装MySQL"
rpm -Uvh $OSS/01_mysql-community-common-5.7.16-1.el7.x86_64.rpm 1>/dev/null 2>&1
rpm -Uvh $OSS/02_mysql-community-libs-5.7.16-1.el7.x86_64.rpm 1>/dev/null 2>&1
rpm -Uvh $OSS/03_mysql-community-libs-compat-5.7.16-1.el7.x86_64.rpm 1>/dev/null 2>&1
rpm -Uvh $OSS/04_mysql-community-client-5.7.16-1.el7.x86_64.rpm 1>/dev/null 2>&1
rpm -Uvh $OSS/05_mysql-community-server-5.7.16-1.el7.x86_64.rpm 1>/dev/null 2>&1
systemctl start mysqld
PASSWORD=$(cat /var/log/mysqld.log | grep password | cut -d " " -f 11)
mysql -uroot -p"$PASSWORD" --connect-expired-password --execute='
set password=password("Qs23=zs32");
set global validate_password_length=4;
set global validate_password_policy=0;
set password=password("000000");
update mysql.user set host="%" where user="root";
flush privileges;' 2>/dev/null
}

function init_hive(){
depend_on hadoop mysql
prt "正在初始化HIVE"
[ -z "$HIVE_HOME" ] && HIVE_HOME=/opt/module/hive
rm -rf $HIVE_HOME
install_package apache-hive-3.1.2-bin.tar.gz
mv /opt/module/apache-hive-3.1.2-bin $HIVE_HOME
rm -rf $HIVE_HOME/lib/log4j-slf4j-impl-2.10.0.jar
curl -s $OSS/mysql-connector-java-5.1.27-bin.jar -o $HIVE_HOME/lib/mysql-connector-java-5.1.27-bin.jar

add_site $HIVE_HOME/conf/hive-site.xml "javax.jdo.option.ConnectionURL" "jdbc:mysql://$MYSQL:3306/metastore?useSSL=false"
add_site $HIVE_HOME/conf/hive-site.xml "javax.jdo.option.ConnectionDriverName" "com.mysql.jdbc.Driver"
add_site $HIVE_HOME/conf/hive-site.xml "javax.jdo.option.ConnectionUserName" "root"
add_site $HIVE_HOME/conf/hive-site.xml "javax.jdo.option.ConnectionPassword" "000000"
add_site $HIVE_HOME/conf/hive-site.xml "hive.metastore.warehouse.dir" "/user/hive/warehouse"
add_site $HIVE_HOME/conf/hive-site.xml "hive.metastore.schema.verification" "false"
add_site $HIVE_HOME/conf/hive-site.xml "hive.server2.thrift.port" "10000"
add_site $HIVE_HOME/conf/hive-site.xml "hive.server2.thrift.bind.host" "$(hostname)"
#add_site $HIVE_HOME/conf/hive-site.xml "hive.metastore.uris" "thrift://$(hostname):9083"
add_site $HIVE_HOME/conf/hive-site.xml "hive.metastore.event.db.notification.api.auth" "false"
add_site $HIVE_HOME/conf/hive-site.xml "hive.server2.active.passive.ha.enable" "true"
add_site $HIVE_HOME/conf/hive-site.xml "hive.exec.dynamic.partition.mode" "nonstrict"


sed -i "/HIVE_HOME/d" $ENV_FILE
cat >>  $ENV_FILE << EOF
#HIVE_HOME
export HIVE_HOME=$HIVE_HOME
export PATH=\$PATH:\$HIVE_HOME/bin
EOF
prt "正在初始化HIVE元数据"
mysql -uroot -p000000 --connect-expired-password --execute='
drop database if exists metastore;
create database metastore;' 2>/dev/null
su - $USR -c "schematool -initSchema -dbType mysql -verbose >/dev/null 2>&1 &" 
sed "/property\.hive\.log\.dir/s/.*/property\.hive\.log\.dir = \/opt\/module\/hive\/logs/" $HIVE_HOME/conf/hive-log4j2.properties.template > $HIVE_HOME/conf/hive-log4j2.properties
}

function init_kafka(){
depend_on zookeeper
prt "初始化Kafka"
[ -z "$KAFKA_HOME" ] && KAFKA_HOME=/opt/module/kafka
xcall "rm -rf $KAFKA_HOME"
install_package kafka_2.11-2.4.1.tgz
mv /opt/module/kafka_2.11-2.4.1 $KAFKA_HOME
xsync $KAFKA_HOME

xcall "HOST=\$(hostname);sed -i "s/^broker\.id=.*$/broker\.id=\${HOST: -1}/" $KAFKA_HOME/config/server.properties"
xcall "sed -i 's/^log\.dirs=.*$/log\.dirs=${KAFKA_HOME//\//\\/}\/logs/' $KAFKA_HOME/config/server.properties"
xcall "sed -i 's/^zookeeper\.connect=.*$/zookeeper\.connect=$1\:2181,$2\:2181,$3\:2181\/kafka/' $KAFKA_HOME/config/server.properties"

sed -i "/KAFKA_HOME/d" $ENV_FILE
cat >>  $ENV_FILE << EOF
#KAFKA_HOME
export KAFKA_HOME=$KAFKA_HOME
export PATH=\$PATH:\$KAFKA_HOME/bin
EOF
xsync $ENV_FILE
cat <<'EOF'> $KAFKA_HOME/bin/kafka.sh
#!/bin/bash
case $1 in
"start")
  xcall "kafka-server-start.sh -daemon /opt/module/kafka/config/server.properties"
  ;;
"stop")
  xcall "kafka-server-stop.sh"
  ;;
*)
  echo "Usage: $0 start|stop"
  ;;
esac
EOF
chown $USR:$USR $KAFKA_HOME/bin/kafka.sh
chmod +x $KAFKA_HOME/bin/kafka.sh
}

function init_flume(){
  depend_on hadoop
  prt "正在初始化Flume"
  xcall "rm -rf /opt/module/flume"
  install_package apache-flume-1.9.0-bin.tar.gz
  mv /opt/module/apache-flume-1.9.0-bin /opt/module/flume
  rm -rf /opt/module/flume/lib/guava-11.0.2.jar
  xsync /opt/module/flume
}

function init_sqoop(){
depend_on hive mysql 
prt "正在初始化Sqoop"
rm -rf /opt/module/sqoop
install_package sqoop-1.4.6.bin__hadoop-2.0.4-alpha.tar.gz
mv /opt/module/sqoop-1.4.6.bin__hadoop-2.0.4-alpha/ /opt/module/sqoop
cat >> /opt/module/sqoop/conf/sqoop-env.sh <<EOF
export HADOOP_COMMON_HOME=$HADOOP_HOME
export HADOOP_MAPRED_HOME=$HADOOP_HOME
export HIVE_HOME=$HIVE_HOME
export ZOOKEEPER_HOME=$ZOOKEEPER_HOME
export ZOOCFGDIR=$ZOOKEEPER_HOME/conf
EOF
curl -s $OSS/mysql-connector-java-5.1.27-bin.jar -o /opt/module/sqoop/lib/mysql-connector-java-5.1.27-bin.jar
}

function init_hbase(){
depend_on hadoop zookeeper
prt "正在初始化HBASE"
[ -z "$HBASE_HOME" ] && HBASE_HOME=/opt/module/hbase
xcall "rm -rf $HBASE_HOME"
install_package hbase-2.0.5-bin.tar.gz
mv /opt/module/hbase-2.0.5 $HBASE_HOME
rm -rf $HBASE_HOME/lib/slf4j-log4j12-1.7.25.jar
xsync $HBASE_HOME

sed -i "/HBASE_HOME/d" $ENV_FILE
cat >>  $ENV_FILE << EOF
#HBASE_HOME
export HBASE_HOME=$HBASE_HOME
export PATH=\$PATH:\$HBASE_HOME/bin
EOF
xsync $ENV_FILE

sed -i '/HBASE_MANAGES_ZK/s/^.*$/export HBASE_MANAGES_ZK=false/' $HBASE_HOME/conf/hbase-env.sh
cat > $HBASE_HOME/conf/regionservers <<EOF
$1
$2
$3
EOF

add_site $HBASE_HOME/conf/hbase-site.xml "hbase.rootdir" "hdfs://$1:8020/hbase"
add_site $HBASE_HOME/conf/hbase-site.xml "hbase.cluster.distributed" "true"
add_site $HBASE_HOME/conf/hbase-site.xml "hbase.zookeeper.quorum" "$1,$2,$3"
add_site $HBASE_HOME/conf/hbase-site.xml "hbase.unsafe.stream.capability.enforce" "false"
add_site $HBASE_HOME/conf/hbase-site.xml "hbase.wal.provider" "filesystem"

xsync $HBASE_HOME/conf
}

function init_spark(){
depend_on hadoop hive
prt "正在初始化Spark"
[ -z "$SPARK_HOME" ] && SPARK_HOME=/opt/module/spark
rm -rf $SPARK_HOME
install_package spark-3.0.0-bin-hadoop3.2.tgz
mv /opt/module/spark-3.0.0-bin-hadoop3.2 $SPARK_HOME
install_package spark-3.0.0-bin-without-hadoop.tgz


curl -s $OSS/mysql-connector-java-5.1.27-bin.jar -o $SPARK_HOME/jars/mysql-connector-java-5.1.27-bin.jar
cat > $HIVE_HOME/conf/spark-defaults.conf <<EOF
spark.master=yarn
spark.eventLog.enabled=true
spark.eventLog.dir=hdfs://$1:8020/spark/history
spark.executor.memory=2g
spark.driver.memory=2g
EOF
add_site $HIVE_HOME/conf/hive-site.xml "spark.yarn.jars" "hdfs://$1:8020/spark/jars/*"
add_site $HIVE_HOME/conf/hive-site.xml "hive.execution.engine" "spark"
add_site $HIVE_HOME/conf/hive-site.xml "hive.spark.client.connect.timeout" "10000ms"
cat > $SPARK_HOME/conf/spark-defaults.conf <<EOF
spark.master=yarn
spark.eventLog.enabled=true
spark.eventLog.dir=hdfs://$1:8020/spark/history
spark.yarn.historyServer.address=$1:18080
spark.history.fs.logDirectory=hdfs://$1:8020/spark/history
spark.sql.adaptive.enabled=true
spark.sql.adaptive.coalescePartitions.enabled=true
spark.sql.hive.convertMetastoreParquet=false
spark.sql.parquet.writeLegacyFormat=true
spark.hadoop.fs.hdfs.impl.disable.cache=true
spark.sql.storeAssignmentPolicy=LEGACY
EOF
sed '/YARN_CONF_DIR/aYARN_CONF_DIR=$HADOOP_HOME/etc/hadoop' $SPARK_HOME/conf/spark-env.sh.template > $SPARK_HOME/conf/spark-env.sh
curl -s $OSS/hadoop-lzo-0.4.20.jar -o $SPARK_HOME/jars/hadoop-lzo-0.4.20.jar

sed -i "/SPARK_HOME/d" $ENV_FILE
cat >>  $ENV_FILE << EOF
#SPARK_HOME
export SPARK_HOME=$SPARK_HOME
export PATH=\$PATH:\$SPARK_HOME/bin:\$SPARK_HOME/sbin
EOF
xsync $ENV_FILE


cp $HIVE_HOME/conf/hive-site.xml $SPARK_HOME/conf/hive-site.xml

su - $USR -c "start-dfs.sh"
su - $USR -c "hdfs dfsadmin -safemode wait"
su - $USR -c "hadoop fs -mkdir -p /spark/history"
su - $USR -c "hadoop fs -mkdir -p /spark/jars"
su - $USR -c "hadoop fs -put /opt/module/spark-3.0.0-bin-without-hadoop/jars/* /spark/jars >/dev/null 2>&1"
su - $USR -c "stop-dfs.sh"
rm -rf /opt/module/spark-3.0.0-bin-without-hadoop
}

function init_mock(){
depend_on hive kafka flume sqoop
prt "初始化采集部分"
xcall "rm -rf /opt/module/applog /opt/module/db_log"
curl -s $OSS/mock_bin.tar.gz | tar zxC /home/$USR
install_package mock.tar.gz
mkdir -p /opt/module/applog/log
xsync /opt/module/applog /opt/module/db_log
curl -s $OSS/flumeinterceptor1116-1.0-SNAPSHOT.jar -o /opt/module/flume/lib/flumeinterceptor1116-1.0-SNAPSHOT.jar
xsync /opt/module/flume/lib
curl -s $OSS/hadoop-lzo-0.4.20.jar -o $HADOOP_HOME/share/hadoop/common/hadoop-lzo-0.4.20.jar
add_site $HADOOP_HOME/etc/hadoop/core-site.xml "io.compression.codecs" "org.apache.hadoop.io.compress.GzipCodec,org.apache.hadoop.io.compress.DefaultCodec,org.apache.hadoop.io.compress.BZip2Codec,org.apache.hadoop.io.compress.SnappyCodec,com.hadoop.compression.lzo.LzoCodec,com.hadoop.compression.lzo.LzopCodec"
add_site $HADOOP_HOME/etc/hadoop/core-site.xml "io.compression.codec.lzo.class" "com.hadoop.compression.lzo.LzoCodec"
xsync $HADOOP_HOME/etc $HADOOP_HOME/share
mysql -uroot -p000000 --execute='
drop database if exists gmall;
CREATE DATABASE gmall CHARACTER SET utf8 COLLATE utf8_general_ci;
use gmall;
source /opt/module/db_log/gmall.sql;' 2>/dev/null
}

function init_azkaban(){
depend_on java mysql
prt "初始化Azkaban"
AZHOME=/opt/module/azkaban
xcall "rm -rf $AZHOME"
mkdir -p $AZHOME
install_package azkaban-db-3.84.4.tar.gz
install_package azkaban-exec-server-3.84.4.tar.gz
install_package azkaban-web-server-3.84.4.tar.gz
mv /opt/module/azkaban-exec-server-3.84.4 $AZHOME/azkaban-exec
xsync $AZHOME
mv /opt/module/azkaban-db-3.84.4 $AZHOME/db
mv /opt/module/azkaban-web-server-3.84.4 $AZHOME/azkaban-web

mysql -uroot -p000000 --connect-expired-password --execute='
set global validate_password_length=4;
set global validate_password_policy=0;
drop database if exists azkaban;
create database azkaban;
CREATE USER if not exists "azkaban"@"%" IDENTIFIED BY "000000";
GRANT ALL ON azkaban.* to "azkaban"@"%" WITH GRANT OPTION;
use azkaban;
source /opt/module/azkaban/db/create-all-sql-3.84.4.sql;' 2>/dev/null

sed -i '/max_allowed_packet/d' /etc/my.cnf
sed -i '/\[mysqld\]/amax_allowed_packet=1024M' /etc/my.cnf
systemctl restart mysqld

add_property $AZHOME/azkaban-exec/conf/azkaban.properties "default.timezone.id" "Asia/Shanghai"
add_property $AZHOME/azkaban-exec/conf/azkaban.properties "azkaban.webserver.url" "http://$1:8081"
add_property $AZHOME/azkaban-exec/conf/azkaban.properties "executor.port" "12321"
add_property $AZHOME/azkaban-exec/conf/azkaban.properties "mysql.host" "$1"
add_property $AZHOME/azkaban-exec/conf/azkaban.properties "mysql.password" "000000"
xsync $AZHOME/azkaban-exec

add_property $AZHOME/azkaban-web/conf/azkaban.properties "default.timezone.id" "Asia/Shanghai"
add_property $AZHOME/azkaban-web/conf/azkaban.properties "mysql.host" "$1"
add_property $AZHOME/azkaban-web/conf/azkaban.properties "mysql.password" "000000"
add_property $AZHOME/azkaban-web/conf/azkaban.properties "azkaban.executorselector.filters" "StaticRemainingFlowSize,CpuStatus"
sed -i '/<azkaban-users>/a<user password="atguigu" roles="metrics,admin" username="atguigu"\/>' $AZHOME/azkaban-web/conf/azkaban-users.xml
prt "生成控制脚本az.sh"
cat <<'EOF'> /home/$USR/bin/az.sh
#!/bin/bash
case $1 in
"start")
  xcall 'cd /opt/module/azkaban/azkaban-exec;bin/start-exec.sh;sleep 3;curl -sG "localhost:12321/executor?action=activate"&&echo'
  cd /opt/module/azkaban/azkaban-web
  bin/start-web.sh
;;
"stop")
  xcall 'cd /opt/module/azkaban/azkaban-exec;bin/shutdown-exec.sh'
  cd /opt/module/azkaban/azkaban-web
  bin/shutdown-web.sh
;;
*)
  echo "usage: $0 start|stop"
;;
esac
EOF
chown $USR:$USR /home/$USR/bin/az.sh
chmod +x /home/$USR/bin/az.sh
}

function init_presto(){
depend_on hive mysql 
prt "初始化presto"
PRESTO_SERVER=/opt/module/presto
xcall "rm -rf $PRESTO_SERVER"
install_package presto-server-0.196.tar.gz
mv /opt/module/presto-server-0.196 $PRESTO_SERVER
mkdir $PRESTO_SERVER/data $PRESTO_SERVER/etc
cat <<'EOF' > $PRESTO_SERVER/etc/jvm.config
-server
-Xmx16G
-XX:+UseG1GC
-XX:G1HeapRegionSize=32M
-XX:+UseGCOverheadLimit
-XX:+ExplicitGCInvokesConcurrent
-XX:+HeapDumpOnOutOfMemoryError
-XX:+ExitOnOutOfMemoryError
EOF
mkdir $PRESTO_SERVER/etc/catalog
add_property $PRESTO_SERVER/etc/catalog/hive.properties "connector.name" "hive-hadoop2"
add_property $PRESTO_SERVER/etc/catalog/hive.properties "hive.metastore.uri" "thrift://hadoop102:9083"
xsync $PRESTO_SERVER
add_property $PRESTO_SERVER/etc/node.properties "node.environment" "production"
add_property $PRESTO_SERVER/etc/node.properties "node.data-dir" "/opt/module/presto/data"
add_property $PRESTO_SERVER/etc/node.properties "node.id" "$(uuidgen)"
rsync -av $PRESTO_SERVER/etc/node.properties hadoop104:$PRESTO_SERVER/etc
add_property $PRESTO_SERVER/etc/node.properties "node.id" "$(uuidgen)"
rsync -av $PRESTO_SERVER/etc/node.properties hadoop103:$PRESTO_SERVER/etc
add_property $PRESTO_SERVER/etc/node.properties "node.id" "$(uuidgen)"

add_property $PRESTO_SERVER/etc/config.properties "coordinator" "false"
add_property $PRESTO_SERVER/etc/config.properties "http-server.http.port" "8881"
add_property $PRESTO_SERVER/etc/config.properties "query.max-memory" "50GB"
add_property $PRESTO_SERVER/etc/config.properties "discovery.uri" "http://hadoop102:8881"
xsync $PRESTO_SERVER/etc/config.properties
add_property $PRESTO_SERVER/etc/config.properties "coordinator" "true"
add_property $PRESTO_SERVER/etc/config.properties "node-scheduler.include-coordinator" "false"
add_property $PRESTO_SERVER/etc/config.properties "discovery-server.enabled" "true"
curl $OSS/presto-cli-0.196-executable.jar -o $PRESTO_SERVER/prestocli
chmod +x $PRESTO_SERVER/prestocli
curl $OSS/yanagishima-18.0.zip -o /opt/module/yanagishima-18.zip
unzip /opt/module/yanagishima-18.zip -d /opt/module
rm -rf /opt/module/yanagishima-18.zip
add_property /opt/module/yanagishima-18.0/yanagishima.properties "jetty.port" "7080"
add_property /opt/module/yanagishima-18.0/yanagishima.properties "presto.datasources" "atguigu-presto"
add_property /opt/module/yanagishima-18.0/yanagishima.properties "presto.coordinator.server.atguigu-presto" "http://hadoop102:8881"
add_property /opt/module/yanagishima-18.0/yanagishima.properties "catalog.atguigu-presto" "hive"
add_property /opt/module/yanagishima-18.0/yanagishima.properties "schema.atguigu-presto" "default"
add_property /opt/module/yanagishima-18.0/yanagishima.properties "sql.query.engines" "presto"
}

function init_kylin(){
depend_on hadoop hive hbase spark
prt "正在初始化Kylin"
KYLIN_HOME=/opt/module/kylin
rm -rf $KYLIN_HOME
install_package apache-kylin-3.0.2-bin.tar.gz
mv /opt/module/apache-kylin-3.0.2-bin $KYLIN_HOME
sed -i "/^spark_dependency/s/\(! -name '.slf4j.'\)\( ! -name '.calcite.'\)/\1 ! -name '*jackson*' ! -name '*metastore*'\2/" $KYLIN_HOME/bin/find-spark-dependency.sh
}

function init_zeppelin(){
depend_on kylin
prt "正在初始化Zeppelin"
ZEPPELIN_HOME=/opt/module/zeppelin
rm -rf $ZEPPELIN_HOME
install_package zeppelin-0.8.0-bin-all.tgz
mv /opt/module/zeppelin-0.8.0-bin-all $ZEPPELIN_HOME
}

function init_shucang(){
  depend_on mock azkaban kylin
  curl -s $OSS/finish.tar.gz | tar zxC /home/$USR
}

xcall "killall -9 java" 2>/dev/null
for i in $*; do
  eval "init_$i $CLUSTER"
done

xcall "chown -R $USR:$USR /opt/module"