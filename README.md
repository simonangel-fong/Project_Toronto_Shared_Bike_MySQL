# Data Warehouse Project - Toronto Shared Bike (MySQL Solution)

A data warehouse project of Toronto Shared Bike using MySQL database.

- [Data Warehouse Project - Toronto Shared Bike (MySQL Solution)](#data-warehouse-project---toronto-shared-bike-mysql-solution)
  - [Data Warehouse](#data-warehouse)
    - [Logical Design](#logical-design)
    - [Physical Implementation](#physical-implementation)
    - [Connect with MySQL Workbench](#connect-with-mysql-workbench)
  - [ETL Pipeline](#etl-pipeline)
    - [Confirm](#confirm)
    - [Export Processed Data](#export-processed-data)

---

## Data Warehouse

- Data Source:
  - https://open.toronto.ca/dataset/bike-share-toronto-ridership-data/

### Logical Design

![pic](./pic/Logical_design_ERD.png)

---

### Physical Implementation

- Initialize PostgreSQL Instance

```sh
cd pgsql
docker compose up -d
```

---

### Connect with MySQL Workbench

- Connection

![pic](./pic/connect01.png)

- Tables & views

![pic](./pic/connect02.png)

---

## ETL Pipeline

- Diagram

![pic](./pic/etl.gif)

- Extract

```sh
docker exec -it mysql bash /scripts/etl/extract.sh
```

![pic](./pic/etl01.png)

- Transform

```sh
docker exec -it mysql bash /scripts/etl/transform.sh
```

![pic](./pic/etl02.png)

```sh
docker exec -it mysql bash /scripts/etl/load.sh
```

![pic](./pic/etl03.png)

- Refresh Table(MV)

```sh
docker exec -it mysql bash /scripts/mv/mv_refresh.sh
```

![pic](./pic/mv01.png)

---

### Confirm

- Time dimension

```sh
SELECT
	dim_year
	, dim_month
	, dim_hour
	, dim_user
	, trip_count
	, duration_sum
FROM toronto_shared_bike.mv_user_time
ORDER BY
    dim_year
    , dim_month
    , dim_hour
    , dim_user
;
```

![pic](./pic/query01.png)

- Station dimension

```sh
SELECT
	dim_year
	, dim_user
	, dim_station
	, trip_count
FROM toronto_shared_bike.mv_user_station
ORDER BY
    dim_year
    , dim_user
    , trip_count DESC
;
```

![pic](./pic/query02.png)

---

### Export Processed Data

```sh
docker exec -it mysql bash /scripts/export/export.sh
```

![pic](./pic/export01.png)
