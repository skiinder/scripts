#!/usr/bin/env bash
CHECK_SHELL="table_check.sh"

DT=$1

#ODS
$CHECK_SHELL \
-d "$DT" \
-n null_id \
-c id \
-v 0:10 \
-t ods_activity_info

$CHECK_SHELL -d "$DT" -n range -c final_amount -v 0:100000:0:100 -t ods_order_info

$CHECK_SHELL -d "$DT" -n dup -c id -v 0:10 -t ods_activity_info

$CHECK_SHELL -d "$DT" -n day_on_day -c id -v -5:10 -t ods_activity_info

$CHECK_SHELL -d "$DT" -n week_on_week -c id -v -5:10 -t ods_activity_info


