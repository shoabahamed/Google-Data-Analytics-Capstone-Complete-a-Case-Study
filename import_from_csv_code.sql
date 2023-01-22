--loads a the csv file from disk and saves it in a table. Repeat it for all the csv file with by changing the tablename and path 
 CREATE TABLE dbo.data_202112(
	ride_id	nvarchar(50) NOT NULL, 
	rideable_type	nvarchar(50),	
	started_at	datetime2(7) NOT NULL,	
	ended_at	datetime2(7) NOT NULL,	
	start_station_name	nvarchar(100),	
	start_station_id	nvarchar(50),	
	end_station_name	nvarchar(100),	
	end_station_id	nvarchar(50),	
	start_lat	float,	
	start_lng	float,	
	end_lat	float,	
	end_lng	float,	
	member_casual	nvarchar(50) NOT NULL	
 )

-- import the file
BULK INSERT dbo.data_202112
FROM 'F:/google data analytics/Course 8/Case Study 1 Cyclist/Datasets/Backup/202112-tripdata.csv'
WITH
(
        FORMAT='CSV',
        FIRSTROW=2
)
GO






