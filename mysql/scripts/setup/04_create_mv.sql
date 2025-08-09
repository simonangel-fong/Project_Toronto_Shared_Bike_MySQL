\! echo
\! echo "$(date '+%Y-%m-%d %H:%M:%S') INFO - ########## Task: Create MV Tables ##########"
\! echo 

USE toronto_shared_bike;

-- ####################
-- Create mv_user_time
-- ####################
CREATE TABLE IF NOT EXISTS mv_user_time (
    dim_year INT,
    dim_month INT,
    dim_hour INT,
    dim_user VARCHAR(100),
    trip_count BIGINT,
    duration_sum BIGINT,
    duration_avg DECIMAL(10, 2)
);

-- Index
CREATE INDEX idx_mv_time 
ON mv_user_time (dim_year, dim_month, dim_hour);

\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Created table mv_user_time."

-- ####################
-- Create mv_user_station
-- ####################
CREATE TABLE IF NOT EXISTS mv_user_station (
    trip_count INT,
    dim_station VARCHAR(100),
    dim_year INT,
    dim_user VARCHAR(100)
);

-- Indexes
CREATE INDEX idx_mv_user_station_year 
ON mv_user_station (dim_year);

CREATE INDEX idx_mv_user_station_station 
ON mv_user_station (dim_station);

\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Created table mv_user_station."

-- ####################
-- Create mv_station_count
-- ####################
CREATE TABLE IF NOT EXISTS mv_station_count (
    station_count INT,
    dim_year INT
);

\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Created table mv_station_count."

-- ####################
-- Create mv_bike_count
-- ####################
CREATE TABLE IF NOT EXISTS mv_bike_count (
    bike_count INT,
    dim_year INT
);

\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Created table mv_bike_count."

\! echo
\! echo "$(date '+%Y-%m-%d %H:%M:%S') INFO - ########## Task Completed: Create MV Tables ##########"
\! echo 