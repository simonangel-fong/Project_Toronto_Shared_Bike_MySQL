use toronto_shared_bike;

SHOW GLOBAL VARIABLES LIKE 'local_infile';

LOAD DATA LOCAL INFILE '/data/2019/Ridership-2019-Q1.csv'
    INTO TABLE staging_trip
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
            
            
SELECT count(*)
FROM staging_trip;

commit;