#!/usr/bin/env python
# -*- coding: utf-8 -*-

import mysql.connector
import sys
import smtplib
from email.mime.text import MIMEText
from email.header import Header
import datetime


def get_yesterday():
    today = datetime.date.today()
    oneday = datetime.timedelta(days=1)
    yesterday = today - oneday
    return yesterday


def mail_alert(message):
    mail_host = "smtp.126.com"
    mail_user = "skiinder@126.com"
    mail_pass = "KADEMQZWCPFWZETF"

    sender = mail_user
    receivers = [mail_user]

    mail_content = MIMEText(''.join(['<html>', '<br>'.join(message), '</html>']), 'html', 'utf-8')
    mail_content['from'] = sender
    mail_content['to'] = receivers[0]
    mail_content['Subject'] = Header('数据监控错误', 'utf-8')

    try:
        smtp = smtplib.SMTP_SSL()
        smtp.connect(mail_host, 465)
        smtp.login(mail_user, mail_pass)
        content_as_string = mail_content.as_string()
        smtp.sendmail(sender, receivers, content_as_string)
    except smtplib.SMTPException as e:
        print e


def main(argv):
    # 如果没有传入日期参数，将日期定为昨天
    if len(argv) >= 2:
        dt = argv[1]
    else:
        dt = str(get_yesterday())

    # 初始化警告正文
    alert_string = []

    # 查询所有指标错误的记录
    connect = mysql.connector.connect(user="root", password="000000", host="hadoop102", database="test")
    cursor = connect.cursor()
    query = ("select tbl, norm, comm, norm_value, norm_value_min, norm_value_max from ind "
             "where dt = '" + dt + "' and norm_value not between norm_value_min and norm_value_max")
    cursor.execute(query)
    for (tbl, norm, comm, norm_value, norm_value_min, norm_value_max) in cursor:
        alert_string.append('%s表异常，指标%s值为%s，超出范围%s-%s，参考信息%s。' % (
            str(tbl), str(norm), norm_value, norm_value_min, norm_value_max, str(comm)))

    # 如果警告数量大于0，发送警告
    if len(alert_string) > 0:
        mail_alert(alert_string)


if __name__ == "__main__":
    main(sys.argv)
