
-- Connect / use DB
USE toronto_shared_bike;

-- Show current database and user
SELECT 
  DATABASE()      AS database_name,
  CURRENT_USER()  AS username
;

SET SQL_SAFE_UPDATES = 0;
START TRANSACTION;

-- ============================================================================
-- Data processing: Remove rows with NULLs in Key columns
-- ============================================================================
\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Removing rows with NULLs ..."
-- Remove rows with NULL values in key columns
DELETE FROM staging_trip
WHERE trip_id IS NULL
   OR trip_duration IS NULL
   OR start_time IS NULL
   OR start_station_id IS NULL
   OR end_station_id IS NULL;

-- Remove rows where key columns contain the literal string "NULL"
DELETE FROM staging_trip
WHERE trip_id = 'NULL'
   OR trip_duration = 'NULL'
   OR start_time = 'NULL'
   OR start_station_id = 'NULL'
   OR end_station_id = 'NULL';

-- ============================================================================
-- Key columns processing: Remove rows with invalid data types or formats
-- ============================================================================

\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Remove rows with invalid data types..."
DELETE FROM staging_trip
WHERE NOT REGEXP_LIKE(trip_id, '^[0-9]+$')
   OR NOT REGEXP_LIKE(trip_duration, '^[0-9]+(\\.[0-9]+)?$')
   OR STR_TO_DATE(start_time, '%m/%d/%Y %H:%i') IS NULL
   OR NOT REGEXP_LIKE(start_station_id, '^[0-9]+$')
   OR NOT REGEXP_LIKE(end_station_id, '^[0-9]+$');

-- ============================================================================
-- Key column processing (trip durations): Remove rows with non-positive value
-- ============================================================================
\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Remove rows with non-positive duration..."
DELETE FROM staging_trip
WHERE CAST(trip_duration AS DECIMAL(18,6)) <= 0;

-- ============================================================================
-- Non-critical columns processing
-- ============================================================================

-- Fix invalid or NULL end_time values
\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Fix invalid or NULL end_time values..."
UPDATE staging_trip
SET end_time = DATE_FORMAT(
    DATE_ADD(STR_TO_DATE(start_time, '%m/%d/%Y %H:%i'),
             INTERVAL CAST(trip_duration AS DECIMAL(18,6)) SECOND),
    '%m/%d/%Y %H:%i'
)
WHERE end_time IS NULL
   OR STR_TO_DATE(end_time, '%m/%d/%Y %H:%i') IS NULL
   OR NOT REGEXP_LIKE(end_time, '^[0-9]{2}/[0-9]{2}/[0-9]{4} [0-9]{2}:[0-9]{2}$');

\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Substitute missing station names with 'UNKNOWN'..."
-- Substitute missing station names with 'UNKNOWN'
UPDATE staging_trip
SET start_station_name = 'UNKNOWN'
WHERE start_station_name IS NULL
   OR TRIM(start_station_name) = 'NULL';

UPDATE staging_trip
SET end_station_name = 'UNKNOWN'
WHERE end_station_name IS NULL
   OR TRIM(end_station_name) = 'NULL';

\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Substitute missing user_type with 'UNKNOWN'..."
-- Substitute missing user_type with 'UNKNOWN'
UPDATE staging_trip
SET user_type = 'UNKNOWN'
WHERE user_type IS NULL;

\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Substitute invalid or missing bike_id with '-1'..."
-- Substitute invalid or missing bike_id with '-1'
UPDATE staging_trip
SET bike_id = '-1'
WHERE bike_id IS NULL
   OR (NOT REGEXP_LIKE(bike_id, '^[0-9]+$') AND bike_id <> '-1');

\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Substitute missing model with 'UNKNOWN'..."
-- Substitute missing model with 'UNKNOWN'
UPDATE staging_trip
SET model = 'UNKNOWN'
WHERE model IS NULL;

\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Remove carriage return characters from user_type..."
-- Remove carriage return characters from user_type
UPDATE staging_trip
SET user_type = REPLACE(user_type, CHAR(13), '')
WHERE INSTR(user_type, CHAR(13)) > 0;

COMMIT;

SET SQL_SAFE_UPDATES = 1;