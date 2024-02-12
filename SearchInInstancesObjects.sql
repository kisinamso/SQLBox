DROP TABLE IF EXISTS #temp	
CREATE TABLE #temp (
 DBNAME VARCHAR(1000)
,ObjectName VARCHAR(1000)
,[Definition] NVARCHAR(MAX)
)
INSERT INTO #temp
EXEC sp_msforeachdb'USE [?]
SELECT QUOTENAME(''?''),OBJECT_NAME(object_id),definition FROM sys.sql_modules where definition LIKE ''%ENTERSEARCHKEYWORD%'''

 SELECT * FROM #temp
