#!/usr/bin/env bash
# -*- coding: utf-8 -*-
while getopts "t:d:c:n:v:" arg; do
    case $arg in
    t)
        TABLE=$OPTARG
        ;;
    d)
        DT=$OPTARG
        ;;
    c)
        COL=$OPTARG
        ;;
    n)
        NORM=$OPTARG
        ;;
    v)
        VALUE=$OPTARG
        ;;
    ?)
        echo "unkonw argument"
        exit 1
        ;;
    esac
done

HIVE_DB=gmall
HIVE_ENGINE=hive
mysql_user="root"
mysql_passwd="000000"
mysql_host="hadoop102"
mysql_DB="test"
mysql_tbl="ind"

function null_id() {
    array=(${VALUE//:/ })
    MIN=${array[0]}
    MAX=${array[1]}
    RESULT=$($HIVE_ENGINE -e "select count(1) from $HIVE_DB.$TABLE where dt='$DT' and $COL is null;")
    mysql -h"$mysql_host" -u"$mysql_user" -p"$mysql_passwd" \
        -e"INSERT INTO $mysql_DB.$mysql_tbl VALUES('$DT', '$TABLE', 'null_id', $RESULT, $MIN, $MAX, '$COL') 
    ON DUPLICATE KEY UPDATE norm_value=$RESULT, norm_value_min=$MIN, norm_value_max=$MAX, comm='$COL';"
}

function range() {
    array=(${VALUE//:/ })
    RANGE_MIN=${array[0]}
    RANGE_MAX=${array[1]}
    MIN=${array[2]}
    MAX=${array[3]}
    RESULT=$($HIVE_ENGINE -e "select count(1) from $HIVE_DB.$TABLE where dt='$DT' and $COL not between $RANGE_MIN and $RANGE_MAX;")
    mysql -h"$mysql_host" -u"$mysql_user" -p"$mysql_passwd" \
        -e"INSERT INTO $mysql_DB.$mysql_tbl VALUES('$DT', '$TABLE', 'range', $RESULT, $MIN, $MAX, '$COL') 
    ON DUPLICATE KEY UPDATE norm_value=$RESULT, norm_value_min=$MIN, norm_value_max=$MAX, comm='$COL';"
}

function dup() {
    array=(${VALUE//:/ })
    MIN=${array[0]}
    MAX=${array[1]}
    RESULT=$($HIVE_ENGINE -e "select count(1) from (select $COL from $HIVE_DB.$TABLE where dt='$DT' group by $COL having count($COL)>1) t1;")
    mysql -h"$mysql_host" -u"$mysql_user" -p"$mysql_passwd" \
        -e"INSERT INTO $mysql_DB.$mysql_tbl VALUES('$DT', '$TABLE', 'duplicate', $RESULT, $MIN, $MAX, '$COL') 
    ON DUPLICATE KEY UPDATE norm_value=$RESULT, norm_value_min=$MIN, norm_value_max=$MAX, comm='$COL';"
}

function day_on_day() {
    array=(${VALUE//:/ })
    MIN=${array[0]}
    MAX=${array[1]}
    YESTODAY=$($HIVE_ENGINE -e "select count(1) from $HIVE_DB.$TABLE where dt=date_add('$DT',-1);")
    TODAY=$($HIVE_ENGINE -e "select count(1) from $HIVE_DB.$TABLE where dt='$DT';")
    if [ $YESTODAY -ne 0 ]; then
        RESULT=$(awk "BEGIN{print ($TODAY-$YESTODAY)/$YESTODAY*100}")
    else
        RESULT=10000
    fi
    mysql -h"$mysql_host" -u"$mysql_user" -p"$mysql_passwd" \
        -e"INSERT INTO $mysql_DB.$mysql_tbl VALUES('$DT', '$TABLE', 'day_on_day', $RESULT, $MIN, $MAX, '$COL') 
    ON DUPLICATE KEY UPDATE norm_value=$RESULT, norm_value_min=$MIN, norm_value_max=$MAX, comm='$COL';"
}

function week_on_week() {
    array=(${VALUE//:/ })
    MIN=${array[0]}
    MAX=${array[1]}
    LASTWEEK=$($HIVE_ENGINE -e "select count(1) from $HIVE_DB.$TABLE where dt between date_add('$DT',-13) and date_add('$DT',-7);")
    THISWEEK=$($HIVE_ENGINE -e "select count(1) from $HIVE_DB.$TABLE where dt between date_add('$DT',-6) and '$DT';")
    if [ $LASTWEEK -ne 0 ]; then
        RESULT=$(awk "BEGIN{print ($THISWEEK-$LASTWEEK)/$LASTWEEK*100}")
    else
        RESULT=10000
    fi
    mysql -h"$mysql_host" -u"$mysql_user" -p"$mysql_passwd" \
        -e"INSERT INTO $mysql_DB.$mysql_tbl VALUES('$DT', '$TABLE', 'week_on_week', $RESULT, $MIN, $MAX, '$COL') 
    ON DUPLICATE KEY UPDATE norm_value=$RESULT, norm_value_min=$MIN, norm_value_max=$MAX, comm='$COL';"
}

function std_dev() {
    array=(${VALUE//:/ })
    MIN=${array[0]}
    MAX=${array[1]}
    RESULT=$($HIVE_ENGINE -e "select std($COL) from $HIVE_DB.$TABLE where dt='$DT';")
    mysql -h"$mysql_host" -u"$mysql_user" -p"$mysql_passwd" \
        -e"INSERT INTO $mysql_DB.$mysql_tbl VALUES('$DT', '$TABLE', 'std_dev', $RESULT, $MIN, $MAX, '$COL') 
    ON DUPLICATE KEY UPDATE norm_value=$RESULT, norm_value_min=$MIN, norm_value_max=$MAX, comm='$COL';"
}

function consistency() {
    array=(${VALUE//:/ })
    CON_TABLE=${array[0]}
    MIN=${array[1]}
    MAX=${array[2]}
    THIS=$($HIVE_ENGINE -e "select count(1) from $HIVE_DB.$TABLE where dt='$DT';")
    THAT=$($HIVE_ENGINE -e "select count(1) from $CON_TABLE where dt='$DT';")
    RESULT=$(awk "BEGIN{print $THAT-$THIS}")
    mysql -h"$mysql_host" -u"$mysql_user" -p"$mysql_passwd" \
        -e"INSERT INTO $mysql_DB.$mysql_tbl VALUES('$DT', '$TABLE', 'consistency', $RESULT, $MIN, $MAX, '$CON_TABLE') 
    ON DUPLICATE KEY UPDATE norm_value=$RESULT, norm_value_min=$MIN, norm_value_max=$MAX, comm='$CON_TABLE';"
}

case $NORM in
"null_id"|"range"|"dup"|"day_on_day"|"week_on_week"|"std_dev")
    $NORM
    ;;
esac
