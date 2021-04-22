drop table if exists test.ind;
create table test.ind
(
    dt                     date comment '日期'        not null,
    tbl                    varchar(20) comment '表名' not null,
    col                    varchar(20) comment '列名' not null,
    null_id                int comment '空值个数'          default null,
    null_id_max            int comment '空值指标上限'        default null,
    null_id_min            int comment '空值指标下限'        default null,
    rng                    int comment '值域错误个数'        default null,
    rng_max                int comment '值域指标上限'        default null,
    rng_min                int comment '值域指标下限'        default null,
    dup                    int comment '重复值个数'         default null,
    dup_max                int comment '重复值指标上限'       default null,
    dup_min                int comment '重复值指标下限'       default null,
    day_on_day_ratio       double comment '环比(天)'      default null,
    day_on_day_ratio_max   double comment '环比指标上限'     default null,
    day_on_day_ratio_min   double comment '环比指标下限'     default null,
    week_on_week_ratio     double comment '同比(周)'      default null,
    week_on_week_ratio_max double comment '同比指标上限'     default null,
    week_on_week_ratio_min double comment '同比指标下限'     default null,
    std_div                double comment '标准差'        default null,
    std_div_max            double comment '标准差指标上限'    default null,
    std_div_min            double comment '标准差指标下限'    default null,
    consistency_table      varchar(20) comment '一致性父表' default null,
    consistency_div        int comment '数据量差额'         default null,
    primary key (dt, tbl, col)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8;