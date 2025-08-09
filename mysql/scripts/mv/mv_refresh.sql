
\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Refreshing mv_user_time ..."
REPLACE INTO mv_user_time
SELECT	
    t.dim_time_year     AS dim_year,
    t.dim_time_month    AS dim_month,
    t.dim_time_hour     AS dim_hour,
    u.dim_user_type_name AS dim_user,
    COUNT(*)            AS trip_count,
    SUM(f.fact_trip_duration) AS duration_sum,
    ROUND(AVG(f.fact_trip_duration), 2) AS duration_avg
FROM fact_trip f
JOIN dim_time t 
    ON f.fact_trip_start_time_id = t.dim_time_id
JOIN dim_user_type u
	ON f.fact_trip_user_type_id = u.dim_user_type_id
GROUP BY
	t.dim_time_year,
	t.dim_time_month,
	t.dim_time_hour,
	u.dim_user_type_name;

\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Refreshing mv_user_station ..."
REPLACE INTO mv_user_station
SELECT
  trip_count,
  dim_station,
  dim_year,
  'all' AS dim_user
FROM (
  SELECT
    COUNT(*) AS trip_count,
    s.dim_station_name AS dim_station,
    t.dim_time_year AS dim_year,
    RANK() OVER (PARTITION BY t.dim_time_year ORDER BY COUNT(*) DESC) AS trip_rank
  FROM fact_trip f
  JOIN dim_time t ON f.fact_trip_start_time_id = t.dim_time_id
  JOIN dim_station s ON f.fact_trip_start_station_id = s.dim_station_id
  JOIN dim_user_type u ON f.fact_trip_user_type_id = u.dim_user_type_id
  WHERE s.dim_station_name <> 'UNKNOWN'
  GROUP BY s.dim_station_name, t.dim_time_year
) ranked_station_year_all
WHERE trip_rank <= 10

UNION ALL

SELECT
  trip_count,
  dim_station,
  dim_year,
  dim_user
FROM (
  SELECT
    COUNT(*) AS trip_count,
    t.dim_time_year AS dim_year,
    u.dim_user_type_name AS dim_user,
    s.dim_station_name AS dim_station,
    RANK() OVER (PARTITION BY t.dim_time_year, u.dim_user_type_name ORDER BY COUNT(*) DESC) AS trip_rank
  FROM fact_trip f
  JOIN dim_time t ON f.fact_trip_start_time_id = t.dim_time_id
  JOIN dim_station s ON f.fact_trip_start_station_id = s.dim_station_id
  JOIN dim_user_type u ON f.fact_trip_user_type_id = u.dim_user_type_id
  WHERE s.dim_station_name <> 'UNKNOWN'
  GROUP BY t.dim_time_year, u.dim_user_type_name, s.dim_station_name
) ranked_station_year_user
WHERE trip_rank <= 10;

\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Refreshing mv_station_count ..."
REPLACE INTO mv_station_count
SELECT
    COUNT(DISTINCT f.fact_trip_start_station_id) AS station_count,
    t.dim_time_year AS dim_year
FROM fact_trip f
JOIN dim_time t
  ON f.fact_trip_start_time_id = t.dim_time_id
GROUP BY t.dim_time_year;

\! echo "$(date '+%Y-%m-%d %H:%M:%S') SQL - Refreshing mv_bike_count ..."
REPLACE INTO mv_bike_count
SELECT
    COUNT(DISTINCT f.fact_trip_bike_id) AS bike_count,
    t.dim_time_year AS dim_year
FROM fact_trip f
JOIN dim_time t
  ON f.fact_trip_start_time_id = t.dim_time_id
GROUP BY t.dim_time_year;