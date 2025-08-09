\! echo
\! echo "$(date '+%Y-%m-%d %H:%M:%S') INFO - ########## Task: Create ETL Table ##########"
\! echo 

USE toronto_shared_bike;

-- ####################
-- staging_trip
-- ####################

CREATE TABLE IF NOT EXISTS staging_trip (
    trip_id              VARCHAR(15),
    trip_duration        VARCHAR(15),
    start_time           VARCHAR(50),
    start_station_id     VARCHAR(15),
    start_station_name   VARCHAR(100),
    end_time             VARCHAR(50),
    end_station_id       VARCHAR(15),
    end_station_name     VARCHAR(100),
    bike_id              VARCHAR(15),
    user_type            VARCHAR(50),
    model                VARCHAR(50)
);

\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Created table staging_trip."

-- ####################
-- confirm
-- ####################

\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Confirm table staging_trip:"
SELECT 
	table_name
    , table_schema
	, table_type
FROM information_schema.tables
WHERE table_schema = 'toronto_shared_bike';

\! echo
\! echo "$(date '+%Y-%m-%d %H:%M:%S') INFO - ########## Task Completed: Create ETL Table ##########"
\! echo 