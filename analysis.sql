--NOTE: In SQL we can store hour more than 23 in sql server so we will calculate difference in minutes instead

USE CyclistCaseStudy
GO


/*Preparing Dataset*/
--Creating a view to add all the data from different tables into one table 
CREATE VIEW all_bike_data
AS 
	SELECT * FROM data_202112     --getting all values from rows and adding them thogether
	UNION
	SELECT * FROM data_202201
	UNION 
	SELECT * FROM data_202202
	UNION
	SELECT * FROM data_202203
	UNION 
	SELECT * FROM data_202204
	UNION
	SELECT * FROM data_202205
	UNION 
	SELECT * FROM data_202206
	UNION
	SELECT * FROM data_202207
	UNION 
	SELECT * FROM data_202208
	UNION
	SELECT * FROM data_202209
	UNION 
	SELECT * FROM data_202210
	UNION 
	SELECT * FROM data_202211



-- a stroe procedure which create a global temp table using columns from rideable_type, started_at, ended_at,
-- start_station_id, member_casual and also compute ride_length_minute, day_of_week, month

CREATE PROCEDURE spCreateBikeTempTable  
AS
BEGIN
--create a temp table ##cleaned_bike_data if it is not created
IF NOT EXISTS(SELECT * FROM tempdb..sysobjects WHERE name LIKE '##cleaned_bike_data%')
	CREATE TABLE ##cleaned_bike_data(
		rideable_type NVARCHAR(30),
		started_at SMALLDATETIME NOT NULL,
		ended_at SMALLDATETIME,
		start_station_id NVARCHAR(50),
		member_casual NVARCHAR(20),
		ride_length_minute FLOAT,
		day_of_week TINYINT,
		month TINYINT
	)

	--inserting columns to cleaned_bike_data temp table
	INSERT INTO ##cleaned_bike_data(rideable_type, started_at, ended_at, 
	start_station_id, member_casual, ride_length_minute, day_of_week, month)
	SELECT 
		rideable_type, started_at, ended_at, start_station_id, member_casual,
		--creating ride_length_minute, day_of_week, month for anlaysis
		DATEDIFF(SECOND, started_at, ended_at) / 60.0, --take difference in second and convert to minute
		DATEPART(WEEKDAY, started_at), --which weekday the person took the bike: Sunday-1, Saturday-7
		DATEPART(MONTH, started_at)    -- which month the person took the bike
	FROM all_bike_data
END



--run stored_procedures and create ##cleaned_bike_data temp table
EXECUTE spCreateBikeTempTable


--Wrong datas
SELECT 
	*
FROM
	##cleaned_bike_data
WHERE ride_length_minute <= 0 -- rows where ride_length is in negative which should not be possible
--There are some wrong entries in the datasets  we need to exclude them first


/*Analyzing cleaned Dataset*/


-- Total number of members and casual riders
SELECT 
	member_casual, 
	count(started_at) AS total_bikers
FROM
	##cleaned_bike_data
WHERE ride_length_minute > 0 --to remove irregular data where ride length is less then 0 or equal to zero
GROUP BY
	member_casual

--Avg ride length for members and casual riders
SELECT 
	member_casual, 
	AVG(ride_length_minute) AS average_ride_length
FROM
	##cleaned_bike_data
WHERE ride_length_minute > 0 
GROUP BY
	member_casual



--month
-- average ride length in each month 
SELECT 
	month,
	AVG(ride_length_minute) AS avg_ride_length_minute
FROM 
	##cleaned_bike_data
WHERE ride_length_minute > 0
GROUP BY month 
ORDER BY month


-- number of riders in each month
SELECT 
	month,
	COUNT(started_at) AS total_riders 
FROM 
	##cleaned_bike_data
WHERE ride_length_minute > 0
GROUP BY month 
ORDER BY month


--avg ride time for different bike riders in differnt months
SELECT 
	month, 
	member_casual,
	AVG(ride_length_minute) AS avg_ride_length
FROM	
	##cleaned_bike_data
WHERE ride_length_minute > 0
GROUP BY member_casual, month
ORDER BY month, member_casual


--number of riders for different bike riders in each months
SELECT 
	month, 
	member_casual,
	COUNT(ride_length_minute) AS total_riders
FROM	
	##cleaned_bike_data
WHERE ride_length_minute > 0
GROUP BY member_casual, month
ORDER BY month, member_casual




--weekdays
--average ride length  in different weekdays
SELECT  
	day_of_week,
	AVG(ride_length_minute) as avg_ride_length_minute
FROM
	##cleaned_bike_data
WHERE ride_length_minute > 0
GROUP BY day_of_week
ORDER BY day_of_week



--total riders in different weekdays
SELECT  
	day_of_week,
	COUNT(started_at) as total_riders
FROM
	##cleaned_bike_data
WHERE ride_length_minute > 0
GROUP BY day_of_week
ORDER BY day_of_week



--average ride length for each type of bikers in different weekday
SELECT  
	day_of_week,
	member_casual, 
	AVG(ride_length_minute) as avg_ride_length_minute
FROM
	##cleaned_bike_data
WHERE ride_length_minute > 0
GROUP BY day_of_week, member_casual
ORDER BY day_of_week, member_casual


--total riders for each type of bikers in different weekday
SELECT  
	day_of_week,
	member_casual, 
	COUNT(ride_length_minute) AS total_riders
FROM
	##cleaned_bike_data
WHERE ride_length_minute > 0
GROUP BY day_of_week, member_casual
ORDER BY day_of_week, member_casual



--average ride length in each weekday for different type cylist in different month
SELECT  
	day_of_week,
	member_casual, 
	AVG(ride_length_minute) as avg_ride_length_minute
FROM
	##cleaned_bike_data
WHERE month = 7 AND ride_length_minute > 0
GROUP BY member_casual, day_of_week
ORDER BY day_of_week, member_casual



--rideable type
-- unique bike types
SELECT 
	DISTINCT rideable_type AS ride_types
FROM
	##cleaned_bike_data

--number of people who uses each type of bikes
SELECT 
	rideable_type, 
	COUNT(started_at)
FROM	
	##cleaned_bike_data
GROUP BY rideable_type


--bike type for different bike riders
SELECT 
	rideable_type, 
	member_casual,
	COUNT(started_at) AS total_riders
FROM	
	##cleaned_bike_data
WHERE ride_length_minute > 0
GROUP BY rideable_type, member_casual
ORDER BY rideable_type, member_casual



--max ride length
--ride time by descending order
SELECT 
	TOP 10000 *
FROM 
	##cleaned_bike_data
WHERE ride_length_minute > 0
ORDER BY ride_length_minute DESC


--max ride time for different bikers
SELECT 
	member_casual,
	MAX(ride_length_minute) AS max_ride_length
FROM 
	##cleaned_bike_data
WHERE ride_length_minute > 0
GROUP BY  member_casual
ORDER BY  member_casual


--max ride time for different bikers in different month 
SELECT 
	month,
	member_casual,
	MAX(ride_length_minute) AS max_ride_length
FROM 
	##cleaned_bike_data
WHERE ride_length_minute > 0
GROUP BY month, member_casual
ORDER BY month, member_casual


--exploring further
--ride length range count for different bikers 
WITH temp_table
AS
(SELECT 
	 *,
	CASE	
		WHEN ride_length_minute > 2000  THEN 'Greater than 2000'
		WHEN ride_length_minute <= 2000  AND ride_length_minute > 1000 THEN '1001 to 2000'
		WHEN ride_length_minute <= 1000  AND ride_length_minute > 100 THEN '101 to 1000'
		ELSE 'Less than 101'
	END AS ride_length_category
FROM 
	##cleaned_bike_data
WHERE ride_length_minute > 0)
SELECT 
	ride_length_category, 
	member_casual,
	COUNT(ride_length_category) As category_count
FROM 
	temp_table
GROUP BY ride_length_category, member_casual
ORDER BY ride_length_category



--daily ridetime and riders count
--AVG ride time in each day
SELECT 
	TOP  10000 CONVERT(DATE, started_at) AS dates,
	AVG(ride_length_minute) as avg_ride_length
FROM 
	##cleaned_bike_data
WHERE ride_length_minute >= 0
GROUP BY CONVERT(DATE, started_at)
ORDER BY CONVERT(DATE, started_at)

--AVG ride time in each day by different bikers
SELECT 
	TOP  10000 CONVERT(DATE, started_at) AS dates,
	member_casual,
	AVG(ride_length_minute) as avg_ride_length
FROM 
	##cleaned_bike_data
WHERE ride_length_minute >= 0 
GROUP BY CONVERT(DATE, started_at), member_casual
ORDER BY CONVERT(DATE, started_at)





------DONE WITH ANALYSIS-----
--Creating tables to export to a csv for further visualization in Tableau--

--creating table to build relationship
CREATE TABLE ##month(
	month_id INT PRIMARY KEY,
	month_name NVARCHAR(20)
)

CREATE TABLE ##week(
	week_id INT PRIMARY KEY,
	week_name NVARCHAR(20)
)

--inserting values into ##month
INSERT INTO ##month VALUES(1, 'January')
INSERT INTO ##month VALUES(2, 'February')
INSERT INTO ##month VALUES(3, 'March')
INSERT INTO ##month VALUES(4, 'April')
INSERT INTO ##month VALUES(5, 'May')
INSERT INTO ##month VALUES(6, 'June')
INSERT INTO ##month VALUES(7, 'July')
INSERT INTO ##month VALUES(8, 'August')
INSERT INTO ##month VALUES(9, 'September')
INSERT INTO ##month VALUES(10, 'October')
INSERT INTO ##month VALUES(11, 'November')
INSERT INTO ##month VALUES(12, 'December')


--inserting values to ##week
INSERT INTO ##week VALUES(1, 'Sunday')
INSERT INTO ##week VALUES(2, 'Monday')
INSERT INTO ##week VALUES(3, 'Tuesday')
INSERT INTO ##week VALUES(4, 'Wednesday')
INSERT INTO ##week VALUES(5, 'Thursday')
INSERT INTO ##week VALUES(6, 'Friday')
INSERT INTO ##week VALUES(7, 'Saturday')




--table date_member_avg_time_count
SELECT 
	CONVERT(DATE, started_at) AS dates,
	member_casual as cyclist_type,
	AVG(ride_length_minute) as avg_ride_length,
	COUNT(ride_length_minute) AS total_riders
FROM 
	##cleaned_bike_data
WHERE ride_length_minute >= 0 
GROUP BY CONVERT(DATE, started_at), member_casual
ORDER BY CONVERT(DATE, started_at), member_casual



--table rideable_type_member_count
SELECT 
	rideable_type, 
	member_casual,
	COUNT(started_at) AS total_riders
FROM	
	##cleaned_bike_data
WHERE ride_length_minute > 0
GROUP BY rideable_type, member_casual
ORDER BY rideable_type, member_casual



--table ride_length_category_count
WITH summary
AS
(SELECT 
	 *,
	CASE	
		WHEN ride_length_minute > 2000  THEN 'Greater than 2000'
		WHEN ride_length_minute <= 2000  AND ride_length_minute > 1000 THEN '1001 to 2000'
		WHEN ride_length_minute <= 1000  AND ride_length_minute > 100 THEN '101 to 1000'
		ELSE 'Less than 101'
	END AS ride_length_category
FROM 
	##cleaned_bike_data
WHERE ride_length_minute > 0)
SELECT 
	ride_length_category, 
	member_casual,
	COUNT(ride_length_category) As category_count
FROM 
	summary
GROUP BY ride_length_category, member_casual
ORDER BY ride_length_category








