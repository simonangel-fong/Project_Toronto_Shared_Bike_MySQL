\! echo
\! echo "$(date '+%Y-%m-%d %H:%M:%S') INFO - ########## Task: Create data warehouse tables ##########"
\! echo 

USE toronto_shared_bike;

-- =======================
-- Time Dimension Table
-- =======================
CREATE TABLE IF NOT EXISTS dim_time (
  dim_time_id           DATETIME NOT NULL,
  dim_time_year         INT NOT NULL CHECK (dim_time_year BETWEEN 2000 AND 2999),
  dim_time_quarter      TINYINT NOT NULL CHECK (dim_time_quarter BETWEEN 1 AND 4),
  dim_time_month        TINYINT NOT NULL CHECK (dim_time_month BETWEEN 1 AND 12),
  dim_time_day          TINYINT NOT NULL CHECK (dim_time_day BETWEEN 1 AND 31),
  dim_time_week         TINYINT NOT NULL CHECK (dim_time_week BETWEEN 1 AND 53),
  dim_time_weekday      TINYINT NOT NULL CHECK (dim_time_weekday BETWEEN 1 AND 7),
  dim_time_hour         TINYINT NOT NULL CHECK (dim_time_hour BETWEEN 0 AND 23),
  dim_time_minute       TINYINT NOT NULL CHECK (dim_time_minute BETWEEN 0 AND 59),
  PRIMARY KEY (dim_time_id)
);

CREATE INDEX index_dim_time_year_month
  ON dim_time (dim_time_year, dim_time_month);

\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Created dim_time."

-- =======================
-- Station Dimension Table
-- =======================
CREATE TABLE IF NOT EXISTS dim_station (
  dim_station_id    INT NOT NULL,
  dim_station_name  VARCHAR(100) NOT NULL,
  PRIMARY KEY (dim_station_id)
);

CREATE INDEX index_dim_station_station_name
  ON dim_station (dim_station_name);

\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Created dim_station."

-- =======================
-- Bike Dimension Table
-- =======================
CREATE TABLE IF NOT EXISTS dim_bike (
  dim_bike_id     INT NOT NULL,
  dim_bike_model  VARCHAR(50) NOT NULL,
  PRIMARY KEY (dim_bike_id)
);

\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Created dim_bike."

-- =======================
-- User Type Dimension Table
-- =======================
CREATE TABLE IF NOT EXISTS dim_user_type (
  dim_user_type_id     INT AUTO_INCREMENT,
  dim_user_type_name   VARCHAR(50) NOT NULL,
  PRIMARY KEY (dim_user_type_id),
  UNIQUE KEY (dim_user_type_name)
);

\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Created dim_user_type."

-- =======================
-- Trip Fact Table with PARTITIONs
-- =======================
CREATE TABLE IF NOT EXISTS fact_trip (
  fact_trip_id              	BIGINT AUTO_INCREMENT,
  fact_trip_source_id       	BIGINT NOT NULL,
  fact_trip_duration        	INT NOT NULL,
  fact_trip_start_time_id   	DATETIME NOT NULL,
  fact_trip_end_time_id     	DATETIME NOT NULL,
  fact_trip_start_station_id 	INT NOT NULL,
  fact_trip_end_station_id   	INT NOT NULL,
  fact_trip_bike_id          	INT NOT NULL,
  fact_trip_user_type_id     	INT NOT NULL,
  PRIMARY KEY (fact_trip_id, fact_trip_start_time_id)
) 
PARTITION BY RANGE (YEAR(fact_trip_start_time_id))
SUBPARTITION BY HASH (MONTH(fact_trip_start_time_id))
SUBPARTITIONS 12 (
  PARTITION p_before_2019 VALUES LESS THAN (2019),
  PARTITION p_2019        VALUES LESS THAN (2020),
  PARTITION p_2020        VALUES LESS THAN (2021),
  PARTITION p_2021        VALUES LESS THAN (2022),
  PARTITION p_2022        VALUES LESS THAN (2023),
  PARTITION p_2023        VALUES LESS THAN (2024),
  PARTITION p_2024        VALUES LESS THAN (2025),
  PARTITION p_future      VALUES LESS THAN MAXVALUE
);
  
-- Indexes
CREATE INDEX index_fact_trip_start_time
  ON fact_trip (fact_trip_start_time_id);

CREATE INDEX index_fact_trip_station_pair
  ON fact_trip (fact_trip_start_station_id, fact_trip_end_station_id);

CREATE INDEX index_fact_trip_user_type
  ON fact_trip (fact_trip_user_type_id);

\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Created fact_trip."

\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Confirm tables:"
-- confirm
SELECT 
	table_name
    , table_schema
	, table_type
FROM information_schema.tables
WHERE table_schema = 'toronto_shared_bike';

SELECT
    TABLE_NAME,
    INDEX_NAME,
    GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS indexed_columns,
    INDEX_TYPE,
    CASE NON_UNIQUE WHEN 1 THEN 'Not Unique' ELSE 'Unique' END AS is_unique
FROM
    INFORMATION_SCHEMA.STATISTICS
WHERE
    TABLE_SCHEMA = 'toronto_shared_bike'
GROUP BY
    TABLE_NAME, INDEX_NAME, INDEX_TYPE, NON_UNIQUE
ORDER BY
    TABLE_NAME, INDEX_NAME;

\! echo
\! echo "$(date '+%Y-%m-%d %H:%M:%S') INFO - ########## Task Completed: Create data warehouse tables ##########"
\! echo 