#!/usr/bin/env bash
CHECK_SHELL="table_check.sh"

DT=$1
if [ -z $DT ]
then DT=$(date -d '-1 day' +%F)
fi

# ODS
$CHECK_SHELL	-t	ods_order_refund_info	-d	"$DT"	-n day_on_day	-c	id	-v -10:10
$CHECK_SHELL	-t	ods_order_detail	-d	"$DT"	-n day_on_day	-c	id	-v -10:10
$CHECK_SHELL	-t	ods_order_info	-d	"$DT"	-n day_on_day	-c	id	-v -10:10
$CHECK_SHELL	-t	ods_user_info	-d	"$DT"	-n day_on_day	-c	id	-v -10:10
$CHECK_SHELL	-t	ods_payment_info	-d	"$DT"	-n day_on_day	-c	id	-v -10:10
$CHECK_SHELL	-t	ods_refund_payment	-d	"$DT"	-n day_on_day	-c	id	-v -10:10
$CHECK_SHELL	-t	ods_order_refund_info	-d	"$DT"	-n week_on_week	-c	id	-v -50:50
$CHECK_SHELL	-t	ods_order_detail	-d	"$DT"	-n week_on_week	-c	id	-v -50:50
$CHECK_SHELL	-t	ods_order_info	-d	"$DT"	-n week_on_week	-c	id	-v -50:50
$CHECK_SHELL	-t	ods_user_info	-d	"$DT"	-n week_on_week	-c	id	-v -50:50
$CHECK_SHELL	-t	ods_payment_info	-d	"$DT"	-n week_on_week	-c	id	-v -50:50
$CHECK_SHELL	-t	ods_refund_payment	-d	"$DT"	-n week_on_week	-c	id	-v -50:50
$CHECK_SHELL	-t	ods_order_info	-d	"$DT"	-n range	-c	final_amount	-v 0:100000:0:100
# DIM
$CHECK_SHELL	-t	dim_activity_rule_info	-d	"$DT"	-n null_id	-c	id	-v 0:10
$CHECK_SHELL	-t	dim_coupon_info	-d	"$DT"	-n null_id	-c	id	-v 0:10
$CHECK_SHELL	-t	dim_sku_info	-d	"$DT"	-n null_id	-c	id	-v 0:10
$CHECK_SHELL	-t	dim_user_info	-d	"9999-99-99"	-n null_id	-c	id	-v 0:10
$CHECK_SHELL	-t	dim_activity_rule_info	-d	"$DT"	-n dup	-c	id	-v 0:5
$CHECK_SHELL	-t	dim_coupon_info	-d	"$DT"	-n dup	-c	id	-v 0:5
$CHECK_SHELL	-t	dim_sku_info	-d	"$DT"	-n dup	-c	id	-v 0:5
$CHECK_SHELL	-t	dim_user_info	-d	"9999-99-99"	-n dup	-c	id	-v 0:5
# DWD
$CHECK_SHELL	-t	dwd_order_detail	-d	"$DT"	-n null_id	-c	id	-v 0:10
$CHECK_SHELL	-t	dwd_order_info	-d	"$DT"	-n null_id	-c	id	-v 0:10
$CHECK_SHELL	-t	dwd_order_refund_info	-d	"$DT"	-n null_id	-c	id	-v 0:10
$CHECK_SHELL	-t	dwd_payment_info	-d	"$DT"	-n null_id	-c	id	-v 0:10
$CHECK_SHELL	-t	dwd_refund_payment	-d	"$DT"	-n null_id	-c	id	-v 0:10
$CHECK_SHELL	-t	dwd_order_info	-d	"$DT"	-n dup	-c	id	-v 0:5
$CHECK_SHELL	-t	dwd_page_log	-d	"$DT"	-n range	-c	during_time	-v 1000:30000:0:100


