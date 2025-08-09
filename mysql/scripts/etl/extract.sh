#!/usr/bin/bash

# Exit on error
# set -e

DB_NAME="toronto_shared_bike"
DATA_PATH="/data"
STAGING_TB="staging_trip"
CNF_PATH="/scripts/etl/etl.cnf"

echo 
echo "##############################"
echo "ETL - Extract Task..."
echo "##############################"
echo

# Truncate table
mysql --defaults-extra-file=$CNF_PATH \
    -D $DB_NAME \
    -e "TRUNCATE TABLE $STAGING_TB;"

# Check if truncate was successful
if [[ $? -eq 0 ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') INFO - Truncated table."
    echo
else 
    echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR - Failed to truncate table."
    exit 1
fi

# extract csv files
for per_year in {2019..2022}; do
    
    # generate path
    per_year_path="$DATA_PATH/$per_year"

    # Check if directory exists first
    if [[ ! -d "$per_year_path" ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR - Directory not found $per_year_path."
        echo 
        continue
    fi

    # loop all csv file in path
    for csv_file in "$per_year_path"/*.csv; do
        # Check if file exists
        if [[ ! -f "$csv_file" ]]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING - No CSV files found in $per_year_path."
            echo 
            continue
        fi
        
        mysql --defaults-extra-file=$CNF_PATH -D $DB_NAME  -e "
            LOAD DATA LOCAL INFILE '$csv_file'
            INTO TABLE $STAGING_TB
            FIELDS TERMINATED BY ',' 
            OPTIONALLY ENCLOSED BY '\"'
            LINES TERMINATED BY '\n'
            IGNORE 1 LINES
            (
                trip_id,
                trip_duration,
                start_station_id,
                start_time,
                start_station_name,
                end_station_id,
                end_time,
                end_station_name,
                bike_id,
                user_type,
                model
            );
        "

        # Check if the mysql command was successful
        if [[ $? -eq 0 ]]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') INFO - Extracted $csv_file."
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR - Failed to extract $csv_file."
            echo
        fi
    done
done

echo
echo "########## Extract Job finished. ##########"
