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

mysql_user="root"
mysql_passwd="000000"
mysql_host="hadoop102"
mysql_DB="test"
mysql_tbl="ind"

function null_id() {
    array=(${VALUE//:/ })
    MIN=${array[0]}
    MAX=${array[1]}
    RESULT=$(hive -e "select count(1) from $TABLE where dt='$DT' and $COL is null;")
    mysql -h"$mysql_host" -u"$mysql_user" -p"$mysql_passwd" \
        -e"INSERT INTO $mysql_DB.$mysql_tbl (dt, tbl, col, null_id, null_id_min, null_id_max) 
    VALUES($DT, $TABLE, $COL, $RESULT, $MIN, $MAX) ON DUPLICATE KEY 
    UPDATE null_id=$RESULT, null_id_min=$MIN, null_id_max=$MAX;"
}

function range() {
    array=(${VALUE//:/ })
    RANGE_MIN=${array[0]}
    RANGE_MAX=${array[1]}
    MIN=${array[2]}
    MAX=${array[3]}
    RESULT=$(hive -e "select count(1) from $TABLE where dt='$DT' and $COL not between $RANGE_MIN and $RANGE_MAX;")
    mysql -h"$mysql_host" -u"$mysql_user" -p"$mysql_passwd" \
        -e"INSERT INTO $mysql_DB.$mysql_tbl (dt, tbl, col, rng, rng_min, rng_max) 
    VALUES($DT, $TABLE, $COL, $RESULT, $MIN, $MAX) ON DUPLICATE KEY 
    UPDATE rng=$RESULT, rng_min=$MIN, rng_max=$MAX;"
}

function dup() {
    array=(${VALUE//:/ })
    MIN=${array[0]}
    MAX=${array[1]}
    RESULT=$(hive -e "select count(1) from (select $COL from $TABLE where dt='$DT' group by $COL having count($COL)>1) t1;")
    mysql -h"$mysql_host" -u"$mysql_user" -p"$mysql_passwd" \
        -e"INSERT INTO $mysql_DB.$mysql_tbl (dt, tbl, col, dup, dup_min, dup_max) 
    VALUES($DT, $TABLE, $COL, $RESULT, $MIN, $MAX) ON DUPLICATE KEY 
    UPDATE dup=$RESULT, dup_min=$MIN, dup_max=$MAX;"
}

function day_on_day() {
    array=(${VALUE//:/ })
    MIN=${array[0]}
    MAX=${array[1]}
    YESTODAY=$(hive -e "select count(1) from $TABLE where dt=date_add('$DT',-1);")
    TODAY=$(hive -e "select count(1) from $TABLE where dt='$DT';")
    if [ $YESTODAY -ne 0 ]; then
        RESULT=$(awk "BEGIN{print ($TODAY-$YESTODAY)/$YESTODAY*100}")
    else
        RESULT=10000
    fi
    mysql -h"$mysql_host" -u"$mysql_user" -p"$mysql_passwd" \
        -e"INSERT INTO $mysql_DB.$mysql_tbl (dt, tbl, col, day_on_day_ratio, day_on_day_ratio_min, day_on_day_ratio_max) 
    VALUES($DT, $TABLE, $COL, $RESULT, $MIN, $MAX) ON DUPLICATE KEY 
    UPDATE day_on_day_ratio=$RESULT, day_on_day_ratio_min=$MIN, day_on_day_ratio_max=$MAX;"
}

function week_on_week() {
    array=(${VALUE//:/ })
    MIN=${array[0]}
    MAX=${array[1]}
    LASTWEEK=$(hive -e "select count(1) from $TABLE where dt between date_add('$DT',-13) and date_add('$DT',-7);")
    THISWEEK=$(hive -e "select count(1) from $TABLE where dt between date_add('$DT',-6) and '$DT';")
    if [ $LASTWEEK -ne 0 ]; then
        RESULT=$(awk "BEGIN{print ($THISWEEK-$LASTWEEK)/$LASTWEEK*100}")
    else
        RESULT=10000
    fi
    mysql -h"$mysql_host" -u"$mysql_user" -p"$mysql_passwd" \
        -e"INSERT INTO $mysql_DB.$mysql_tbl (dt, tbl, col, week_on_week_ratio, week_on_week_ratio_min, week_on_week_ratio_max) 
    VALUES($DT, $TABLE, $COL, $RESULT, $MIN, $MAX) ON DUPLICATE KEY 
    UPDATE week_on_week_ratio=$RESULT, week_on_week_ratio_min=$MIN, week_on_week_ratio_max=$MAX;"
}

function std_dev() {
    array=(${VALUE//:/ })
    MIN=${array[0]}
    MAX=${array[1]}
    RESULT=$(hive -e "select std($COL) from $TABLE where dt='$DT';")
    mysql -h"$mysql_host" -u"$mysql_user" -p"$mysql_passwd" \
        -e"INSERT INTO $mysql_DB.$mysql_tbl (dt, tbl, col, std_dev, std_dev_min, std_dev_max) 
    VALUES($DT, $TABLE, $COL, $RESULT, $MIN, $MAX) ON DUPLICATE KEY 
    UPDATE std_dev=$RESULT, std_dev_min=$MIN, std_dev_max=$MAX;"
}

function consistency() {
    array=(${VALUE//:/ })
    CON_TABLE=${array[0]}
    MAX=${array[1]}
    THIS=$(hive -e "select count(1) from $TABLE where dt='$DT';")
    THAT=$(hive -e "select count(1) from $CON_TABLE where dt='$DT';")
    RESULT=$(awk "BEGIN{print $THAT-$THIS}")
    mysql -h"$mysql_host" -u"$mysql_user" -p"$mysql_passwd" \
        -e"INSERT INTO $mysql_DB.$mysql_tbl (dt, tbl, col, consistency_table, consistency_dev) 
    VALUES($DT, $TABLE, $COL, $CON_TABLE, $RESULT) ON DUPLICATE KEY 
    UPDATE consistency_table=$CON_TABLE, consistency_dev=$RESULT;"
}

case $NORM in
"null_id"|"range"|"dup"|"day_on_day"|"week_on_week"|"std_dev"|"consistency")
    $NORM
    ;;
esac
