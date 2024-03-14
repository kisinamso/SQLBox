/*
-----------------------------------------------@kisinamso-----------------------------------------------
|This script returns the unused indexes in an SQL Server Instance.												             |
-----------------------------------------------@kisinamso-----------------------------------------------
*/
DROP TABLE IF EXISTS #Temp
CREATE TABLE #Temp
(
	 DatabaseName   SYSNAME
	,SchemaName		SYSNAME
	,ObjectName		SYSNAME
	,IndexName		SYSNAME
	,IndexID				INT
	,UserSeek			BIGINT
	,UserScans		BIGINT
	,UserLookups		BIGINT
	,UserUpdates		BIGINT
	,TableRows		INT
	,DisableScript		VARCHAR(MAX)
	,DropScript		VARCHAR(MAX)
)
INSERT INTO #Temp
EXEC SP_MSFOREACHDB'
USE [?]
SELECT 
  QUOTENAME(DB_NAME()) AS DatabaseName
, QUOTENAME(SCHEMA_NAME(o.schema_id)) AS SchemaName
, QUOTENAME(o.name) AS ObjectName
, QUOTENAME(i.name) AS IndexName
, i.index_id AS IndexID
, dm_ius.user_seeks AS UserSeek
, dm_ius.user_scans AS UserScans
, dm_ius.user_lookups AS UserLookups
, dm_ius.user_updates AS UserUpdates
, p.TableRows
,''ALTER INDEX '' + QUOTENAME(i.name) + ''ON '' + QUOTENAME(s.name) + ''.'' + QUOTENAME(OBJECT_NAME(dm_ius.OBJECT_ID)) + '' DISABLE'' AS DisableScript
, ''DROP INDEX '' + QUOTENAME(i.name) + '' ON '' + QUOTENAME(s.name) + ''.'' + QUOTENAME(OBJECT_NAME(dm_ius.OBJECT_ID)) AS DropScript

FROM sys.dm_db_index_usage_stats dm_ius
INNER JOIN sys.indexes i ON i.index_id = dm_ius.index_id 
AND dm_ius.OBJECT_ID = i.OBJECT_ID
INNER JOIN sys.objects o ON dm_ius.OBJECT_ID = o.OBJECT_ID
INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
INNER JOIN (SELECT SUM(p.rows) TableRows, p.index_id, p.OBJECT_ID
FROM sys.partitions p GROUP BY p.index_id, p.OBJECT_ID) p
ON p.index_id = dm_ius.index_id AND dm_ius.OBJECT_ID = p.OBJECT_ID
WHERE OBJECTPROPERTY(dm_ius.OBJECT_ID,''IsUserTable'') = 1
AND dm_ius.database_id = DB_ID()
AND i.type_desc = ''nonclustered''
AND i.is_primary_key = 0
AND i.is_unique_constraint = 0
ORDER BY (dm_ius.user_seeks + dm_ius.user_scans + dm_ius.user_lookups) ASC
'

SELECT * FROM #Temp WHERE DatabaseName NOT IN (SELECT QUOTENAME([name]) FROM sys.databases WHERE [database_id] <= 4)
