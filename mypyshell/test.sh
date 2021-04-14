#!/bin/bash
sed -i "/^spark_dependency/s/\(! -name '.slf4j.'\)\( ! -name '.calcite.'\)/\1 ! -name '*jackson*' ! -name '*metastore*'\2/" find-spark-dependency.sh