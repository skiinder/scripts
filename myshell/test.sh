#!/bin/bash
echo ">>>>>>>>  正在修改hosts文件  <<<<<<<<"
set -i '/hadoop10/d' /etc/hosts 
read -p "当前机器应为hadoop102，请输入当前机器IP：" hadoop102_ip
echo "$hadoop102_ip hadoop102" >> /etc/hosts
read -p "请输入hadoop103机器IP：" hadoop103_ip
echo "$hadoop103_ip hadoop103" >> /etc/hosts
read -p "请输入hadoop104机器IP：" hadoop104_ip
echo "$hadoop104_ip hadoop104" >> /etc/hosts


echo ">>>>>>>>  正在为root用户配置免密登录，请按提示输入密码  <<<<<<<<"
rm /root/.ssh
ssh-keygen -t rsa -N '' -f id_rsa -q
ssh-copy-id hadoop102
ssh-copy-id hadoop103
ssh-copy-id hadoop104
rsync -av /etc/host hadoop103:/etc
rsync -av /etc/host hadoop104:/etc
rsync -av /root/.ssh hadoop103:/root
rsync -av /root/.ssh hadoop104:/root


echo ">>>>>>>>  正在创建xcall脚本  <<<<<<<<"
cat <<'EOF' >/bin/xcall
#!/bin/bash
[ -z "$CLUSTER" ] && CLUSTER="hadoop102 hadoop103 hadoop104"
pdsh -w "$CLUSTER" "$*" | sort -k1 | awk -F ": " '{if (host!=$1) {host=$1;print ">>>>>>>>>>>>  "host"  <<<<<<<<<<<<"};$1=null;print $0  }'
EOF
chmod +x /bin/xcall

echo ">>>>>>>>  正在创建xsync脚本  <<<<<<<<"
cat <<'EOF' >/bin/xcall
#!/bin/bash
#1. 判断参数个数
if [ $# -lt 1 ]
then
  echo Not Enough Arguement!
  exit;
fi
#2. 遍历所有文件
for file in $@
do
  #4. 判断文件是否存在
  if [ -e $file ]
  then
    #5. 获取父目录
    pdir=$(cd -P $(dirname $file); pwd)
    #6. 获取当前文件的名称
    fname=$(basename $file)
    xcall "mkdir -p $pdir"
    xcall "rsync -aq $(hostname):$pdir/$fname $pdir"
  else
    echo $file does not exists!
  fi
done
EOF
chmod +x /bin/xsync

xsync /bin/xcall /bin/xsync
for i in hadoop102 hadoop103 hadoop104
do
  ssh $i "hostnamectl --static set-hostname $i"
done

echo ">>>>>>>>  正在生成atguigu用户  <<<<<<<<"
xcall "if id atguigu;then userdel -r atguigu;fi;useradd atguigu"
cp -r /root/.ssh /home/atguigu
chown -R atguigu:atguigu /home/atguigu
xsync /home/atguigu/.ssh

echo ">>>>>>>>  为atguigu用户添加sudo权限  <<<<<<<<"
sed -i '/NOPASSWD/s/#//' /etc/sudoers
xsync /etc/sudoers
xcall "usermod -aG wheel atguigu"

echo ">>>>>>>>  新建相关目录  <<<<<<<<"
xcall "mkdir /opt/module /opt/software"
xcall "chown atguigu:atguigu -R /opt/module /opt/software"


