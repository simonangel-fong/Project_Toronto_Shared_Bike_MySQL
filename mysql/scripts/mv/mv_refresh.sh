#!/usr/bin/bash

CNF_PATH="/scripts/etl/etl.cnf"
DB_NAME="toronto_shared_bike"
SQL_FILE="/scripts/mv/mv_refresh.sql"

echo 
echo "$(date '+%Y-%m-%d %H:%M:%S') INFO - ########## Task: MV Table ##########"
echo 

mysql --defaults-extra-file=$CNF_PATH \
    -D $DB_NAME < $SQL_FILE

echo
echo "$(date '+%Y-%m-%d %H:%M:%S') INFO - ########## Task Completed: MV Table ##########"