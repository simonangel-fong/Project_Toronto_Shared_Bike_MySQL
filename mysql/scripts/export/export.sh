#!/usr/bin/bash

DB_USER="postgres"
DB_NAME="toronto_shared_bike"
VIEW_LIST=("mv_user_time" "mv_user_station" "mv_station_count" "mv_bike_count")
EXPORT_PATH="/export"
CNF_PATH="/scripts/etl/etl.cnf"

echo 
echo "$(date '+%Y-%m-%d %H:%M:%S') INFO - ########## Task: Export MV ##########"
echo 

for VIEW in "${VIEW_LIST[@]}";
do
    view_name="$VIEW"
    csv_file="$EXPORT_PATH/$VIEW.csv"
    
    rm -f $csv_file
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') INFO - Exporting MV $csv_file"
    mysql --defaults-extra-file=$CNF_PATH \
        -D $DB_NAME \
        -e "SELECT * FROM $VIEW INTO OUTFILE '$csv_file' FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n';"
done

echo 
echo "$(date '+%Y-%m-%d %H:%M:%S') INFO - ########## Task Completed: Export MV ##########"
echo 