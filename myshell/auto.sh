#!/bin/bash
cd /root/git/c37fb88d646f6b6d75fa63eba82ee9e0
git pull

#下载必要资源
rm rules -rf
mkdir rules
wget https://github.com/Hackl0us/SS-Rule-Snippet/raw/master/Rulesets/Basic/CN.list -qO rules/in.list
wget https://github.com/Hackl0us/SS-Rule-Snippet/raw/master/Rulesets/Basic/common-ad-keyword.list -qO rules/ad1.list
wget https://github.com/Hackl0us/SS-Rule-Snippet/raw/master/Rulesets/Basic/foreign.list -qO rules/out.list
wget https://github.com/Hackl0us/SS-Rule-Snippet/raw/master/Rulesets/Custom/CN-ad.list -qO rules/ad2.list
wget https://github.com/Hackl0us/SS-Rule-Snippet/raw/master/Rulesets/Custom/ad-domains.list -qO rules/ad3.list
wget https://github.com/Hackl0us/SS-Rule-Snippet/raw/master/Rulesets/Custom/video-ad.list -qO rules/ad4.list
wget https://sub.bikacloud.tech/link/NyRh1MRvXEMIZtw3?surfboard=1 -qO rules/proxy.list

echo "#!MANAGED-CONFIG https://gist.github.com/skiinder/c37fb88d646f6b6d75fa63eba82ee9e0/raw/mine.conf" > rules/tmp.list
cat rules/proxy.list | grep -v \# | grep -v direct | sed -n '/General/,/Proxy Group/p' | sed 's/IPLC//g' | sed '/\[Proxy\]/aDirect = direct\nBlock = reject' >> rules/tmp.list
groups=$(cat rules/tmp.list | grep custom | cut -d " " -f 1 | sed 's/[A-Z].*//g' | sort -r | uniq)

#添加被墙组
rule="Blocked = select"
for group in $groups
do
    rule="$rule, $group"
done
echo $rule >> rules/tmp.list

#添加未被墙组
rule="Other = select"
for group in $groups
do
    rule="$rule, $group"
done
rule="$rule, Direct"
echo $rule >> rules/tmp.list

#添加国内组
rule="Domestic = select, Direct, Other"
echo $rule >> rules/tmp.list

#添加广告组
rule="Advertisement = select, Block, Direct"
echo $rule >> rules/tmp.list

#添加代理组
for group in $groups
do
    members=$(cat rules/tmp.list | grep -v select | grep $group | cut -d " " -f 1)
    rule="$group = select"
    for member in $members
    do
        rule="$rule, $member"
    done
    echo $rule >> rules/tmp.list
done

echo "[Rule]" >> rules/tmp.list
cat rules/out.list | grep force-remote-dns | awk -F "," '{print $1", "$2", Blocked, "$3}' >> rules/tmp.list
cat rules/ad1.list | grep -v '^$' | awk -F "," '{print $1", "$2", Advertisement"}' >> rules/tmp.list
cat rules/ad2.list | grep -v '^$' | awk -F "," '{print $1", "$2", Advertisement"}' >> rules/tmp.list
cat rules/ad4.list | grep -v '^$' | awk -F "," '{print $1", "$2", Advertisement"}' >> rules/tmp.list
cat rules/ad3.list | grep -v '^$' | awk -F "," '{print $1", "$2", Advertisement"}' >> rules/tmp.list
cat rules/in.list | grep -v '^$' | awk -F "," '{print $1", "$2", Domestic"}' >> rules/tmp.list
cat >> rules/tmp.list <<EOF
GEOIP,CN,Domestic
FINAL,Blocked
EOF
cat rules/tmp.list > mine.conf

git add mine.conf
git commit -m "Common update"
git push
