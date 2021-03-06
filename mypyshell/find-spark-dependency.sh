#!/bin/bash

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

source $(cd -P -- "$(dirname -- "$0")" && pwd -P)/header.sh

echo Retrieving Spark dependency...

spark_home=

if [ -n "$SPARK_HOME" ]
then
    verbose "SPARK_HOME is set to: $SPARK_HOME, use it to locate Spark dependencies."
    spark_home=$SPARK_HOME
fi

if [ -z "$SPARK_HOME" ]
then
    verbose "SPARK_HOME wasn't set, use $KYLIN_HOME/spark"
    spark_home=$KYLIN_HOME/spark
fi

if [ ! -d "$spark_home/jars" ]
  then
    quit "spark not found, set SPARK_HOME, or run bin/download-spark.sh"
fi

spark_dependency=`find -L $spark_home/jars -name '*.jar' ! -name '*slf4j*' ! -name '*jackson*' ! -name '*metastore*' ! -name '*calcite*' ! -name '*doc*' ! -name '*test*' ! -name '*sources*' ''-printf '%p:' | sed 's/:$//'`
if [ -z "$spark_dependency" ]
then
    quit "spark jars not found"
else
    verbose "spark dependency: $spark_dependency"
    export spark_dependency
fi
echo "export spark_dependency=$spark_dependency" > ${dir}/cached-spark-dependency.sh

