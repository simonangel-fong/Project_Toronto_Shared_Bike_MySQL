USE toronto_shared_bike;

-- ============================================================================
-- Load dim_time  (INSERT DISTINCT; ignore existing)
-- ============================================================================
\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Loading dim_time ..."
INSERT INTO dim_time (
    dim_time_id,
    dim_time_year,
    dim_time_quarter,
    dim_time_month,
    dim_time_day,
    dim_time_week,
    dim_time_weekday,
    dim_time_hour,
    dim_time_minute
)
SELECT DISTINCT
    STR_TO_DATE(time_value, '%m/%d/%Y %H:%i')                                  AS dim_time_id,
    YEAR(STR_TO_DATE(time_value, '%m/%d/%Y %H:%i'))                             AS dim_time_year,
    QUARTER(STR_TO_DATE(time_value, '%m/%d/%Y %H:%i'))                          AS dim_time_quarter,
    MONTH(STR_TO_DATE(time_value, '%m/%d/%Y %H:%i'))                            AS dim_time_month,
    DAY(STR_TO_DATE(time_value, '%m/%d/%Y %H:%i'))                              AS dim_time_day,
    WEEKOFYEAR(STR_TO_DATE(time_value, '%m/%d/%Y %H:%i'))                       AS dim_time_week,
    DAYOFWEEK(STR_TO_DATE(time_value, '%m/%d/%Y %H:%i'))                        AS dim_time_weekday, -- 1=Sun..7=Sat
    HOUR(STR_TO_DATE(time_value, '%m/%d/%Y %H:%i'))                             AS dim_time_hour,
    MINUTE(STR_TO_DATE(time_value, '%m/%d/%Y %H:%i'))                           AS dim_time_minute
FROM (
    SELECT start_time AS time_value FROM staging_trip
    UNION
    SELECT end_time FROM staging_trip WHERE end_time IS NOT NULL
) combined
WHERE STR_TO_DATE(time_value, '%m/%d/%Y %H:%i') IS NOT NULL
ON DUPLICATE KEY UPDATE
  -- do nothing on duplicates
  dim_time_id = dim_time_id;

-- ============================================================================
-- Load dim_station (use latest name by trip_datetime)
-- ============================================================================
\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Loading dim_station ..."
INSERT INTO dim_station (dim_station_id, dim_station_name)
SELECT station_id, station_name
FROM (
  SELECT
    station_id,
    station_name,
    ROW_NUMBER() OVER (
      PARTITION BY station_id
      ORDER BY trip_datetime DESC
    ) AS rn
  FROM (
    SELECT 
        CAST(start_station_id AS SIGNED)                   AS station_id,
        start_station_name                                 AS station_name,
        STR_TO_DATE(start_time, '%m/%d/%Y %H:%i')          AS trip_datetime
    FROM staging_trip
    WHERE start_station_id IS NOT NULL AND start_station_name IS NOT NULL

    UNION ALL

    SELECT 
        CAST(end_station_id AS SIGNED)                     AS station_id,
        end_station_name                                   AS station_name,
        STR_TO_DATE(end_time, '%m/%d/%Y %H:%i')            AS trip_datetime
    FROM staging_trip
    WHERE end_station_id IS NOT NULL AND end_station_name IS NOT NULL
  ) AS station_times
  WHERE trip_datetime IS NOT NULL
) AS latest_stations
WHERE rn = 1
ON DUPLICATE KEY UPDATE
  dim_station_name = VALUES(dim_station_name);

-- ============================================================================
-- Load dim_bike (pick a non-'UNKNOWN' trimmed model if any; else 'UNKNOWN')
-- ============================================================================
\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Loading dim_bike ..."
INSERT INTO dim_bike (dim_bike_id, dim_bike_model)
SELECT 
  CAST(bike_id AS SIGNED) AS dim_bike_id,
  COALESCE(
    MAX(NULLIF(TRIM(REPLACE(model, CHAR(13), '')), 'UNKNOWN')),
    'UNKNOWN'
  ) AS dim_bike_model
FROM staging_trip
GROUP BY CAST(bike_id AS SIGNED)
ON DUPLICATE KEY UPDATE
  dim_bike_model = VALUES(dim_bike_model);

-- ============================================================================
-- Load dim_user_type
-- ============================================================================
\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Loading dim_user_type ..."
INSERT INTO dim_user_type (dim_user_type_name)
SELECT DISTINCT user_type
FROM staging_trip
WHERE user_type IS NOT NULL
ON DUPLICATE KEY UPDATE
  dim_user_type_name = dim_user_type_name;

-- ============================================================================
-- Load fact_trip
-- ============================================================================
\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Loading fact_trip ..."
INSERT INTO fact_trip (
  fact_trip_source_id,
  fact_trip_duration,
  fact_trip_start_time_id,
  fact_trip_end_time_id,
  fact_trip_start_station_id,
  fact_trip_end_station_id,
  fact_trip_bike_id,
  fact_trip_user_type_id
)
SELECT
  CAST(st.trip_id AS SIGNED)                                                   AS fact_trip_source_id,
  CAST(st.trip_duration AS DECIMAL(18,6))                                      AS fact_trip_duration,
  STR_TO_DATE(st.start_time, '%m/%d/%Y %H:%i')                                 AS fact_trip_start_time_id,
  STR_TO_DATE(st.end_time,   '%m/%d/%Y %H:%i')                                 AS fact_trip_end_time_id,
  CAST(st.start_station_id AS SIGNED)                                          AS fact_trip_start_station_id,
  CAST(st.end_station_id   AS SIGNED)                                          AS fact_trip_end_station_id,
  CAST(st.bike_id          AS SIGNED)                                          AS fact_trip_bike_id,
  dut.dim_user_type_id                                                        AS fact_trip_user_type_id
FROM staging_trip st
JOIN dim_user_type dut
  ON dut.dim_user_type_name = st.user_type
WHERE STR_TO_DATE(st.start_time, '%m/%d/%Y %H:%i') IS NOT NULL
ON DUPLICATE KEY UPDATE
  fact_trip_duration         = VALUES(fact_trip_duration),
  fact_trip_start_time_id    = VALUES(fact_trip_start_time_id),
  fact_trip_end_time_id      = VALUES(fact_trip_end_time_id),
  fact_trip_start_station_id = VALUES(fact_trip_start_station_id),
  fact_trip_end_station_id   = VALUES(fact_trip_end_station_id),
  fact_trip_bike_id          = VALUES(fact_trip_bike_id),
  fact_trip_user_type_id     = VALUES(fact_trip_user_type_id);

-- Confirm
\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Confirm dim_time"
SELECT COUNT(*) AS "dim_time_count"
FROM dim_time;

\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Confirm dim_station"
SELECT COUNT(*) AS "dim_station_count"
FROM dim_station;

\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Confirm dim_bike"
SELECT COUNT(*) AS "dim_bike_count"
FROM dim_bike;

\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Confirm dim_user_type"
SELECT COUNT(*) AS "dim_user_type_count"
FROM dim_user_type;

\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Confirm fact_trip"
SELECT COUNT(*) AS "fact_trip_count"
FROM fact_trip;
