#!/usr/bin/bash

CNF_PATH="/scripts/etl/etl.cnf"
DB_NAME="toronto_shared_bike"
SQL_FILE="/scripts/etl/load.sql"

echo 
echo "##############################"
echo "ETL - Load..."
echo "##############################"
echo

mysql --defaults-extra-file=$CNF_PATH \
    -D $DB_NAME < $SQL_FILE