/*
-----------------------------------------------@kisinamso-----------------------------------------------
|If you want to generate index reorganize or rebuild scripts in a database you can use this script.	|
|I explaid parts to work do to below.									|
-----------------------------------------------@kisinamso-----------------------------------------------
*/
--Please Enter DatabaseName to below.
USE [DatabaseName]
GO
  
DECLARE @param VARCHAR(MAX)
DECLARE curs CURSOR LOCAL FAST_FORWARD FOR
SELECT 
--OBJECT_NAME(ind.OBJECT_ID) AS TableName,
--ind.name AS IndexName, 
--indexstats.index_type_desc AS IndexType, 
--indexstats.avg_fragmentation_in_percent,
CASE 
	WHEN indexstats.avg_fragmentation_in_percent BETWEEN 5 AND 30
	THEN 'ALTER INDEX ' + name + ' ON ' + OBJECT_NAME(ind.OBJECT_ID) + ' REORGANIZE  WITH (ONLINE = ON);'
	WHEN indexstats.avg_fragmentation_in_percent > 30
	THEN 'ALTER INDEX ' + name + ' ON ' + OBJECT_NAME(ind.OBJECT_ID) + ' REBUILD WITH (ONLINE = ON);'	
	ELSE
		NULL
END AS Script

FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) indexstats
INNER JOIN sys.indexes ind ON ind.object_id = indexstats.object_id AND ind.index_id = indexstats.index_id
WHERE indexstats.avg_fragmentation_in_percent >= 5 AND ind.name IS NOT NULL
ORDER BY indexstats.avg_fragmentation_in_percent DESC

OPEN curs

FETCH NEXT FROM curs INTO @param

WHILE @@FETCH_STATUS = 0 
BEGIN
	PRINT(@param)
    EXEC( @param)
    FETCH NEXT FROM curs INTO @param
END

CLOSE curs
DEALLOCATE curs
