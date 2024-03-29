DROP TABLE IF EXISTS #Temp

/*
-----------------------------------------------@kisinamso-----------------------------------------------
|This script gives to you all corrupted statistics in a instance.                                      |
-----------------------------------------------@kisinamso-----------------------------------------------
*/
CREATE TABLE #Temp
(
		 DatabaseName				NVARCHAR(128)
		,SchemaName				NVARCHAR(128)
		,ObjectName					NVARCHAR(128)
		,StatisticsId				INT
		,StatisticsName			NVARCHAR(MAX)
		,FilterDefinition			NVARCHAR(MAX)
		,LastUpdated				DATETIME
		,Rows							BIGINT
		,RowsSampled				BIGINT
		,Steps						INT
		,UnfilteredRows			BIGINT
		,ModificationCounter		BIGINT
)
INSERT INTO #Temp
EXEC sp_msforeachdb'
USE [?]
SELECT 
       DB_NAME() AS DatabaseName,
       OBJECT_SCHEMA_NAME(sp.object_id) AS SchemaName,
       OBJECT_NAME(sp.object_id) AS ObjectName,
       sp.stats_id AS StatisticsId, 
       name AS StatisticName, 
       filter_definition AS FilterDefinition, 
       last_updated AS LastUpdatedDate, 
       rows AS Rows, 
       rows_sampled AS RowsSampled, 
       steps Steps, 
       unfiltered_rows AS UnfilteredRows, 
       modification_counter AS ModificationCounter
FROM sys.stats AS stat
     CROSS APPLY sys.dm_db_stats_properties(stat.object_id, stat.stats_id) AS sp
WHERE (sp.rows <= 500 and sp.modification_counter >= 500)
		or (sp.rows > 500 and sp.modification_counter >= (500 + sp.rows * 0.20))'

SELECT * FROM #Temp
