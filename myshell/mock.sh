#!/bin/bash
DB_HOME=/opt/module/db_log

function add_property(){
if [ ! -e $1 ]
then
touch $1
fi
sed -i "/$2/d" $1
echo "$2=$3" >> $1
}

function mock_data(){
add_property $DB_HOME/application.properties "mock.date" "$1"
java -jar $DB_HOME/gmall2020-mock-db-2021-01-22.jar
}

case $1 in
"init")
add_property $DB_HOME/application.properties "mock.clear" "1"
add_property $DB_HOME/application.properties "mock.clear.user" "1"
mock_data 2020-06-09
add_property $DB_HOME/application.properties "mock.clear" "0"
add_property $DB_HOME/application.properties "mock.clear.user" "0"
for i in 2020-06-10 2020-06-11 2020-06-12 2020-06-13 2020-06-14
do
  mock_data $i
done
;;
*)
mock_data $1
;;
esac
