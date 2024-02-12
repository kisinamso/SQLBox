/*
-----------------------------------------------@kisinamso-----------------------------------------------
|If you want to learn all tables size in a Instance you can take this script.				|
|You can acces to comments below.   									|
-----------------------------------------------@kisinamso-----------------------------------------------
*/
--Drop temp table if exists
DROP TABLE IF EXISTS #List

--Create a new temp table for return
CREATE TABLE #List 
(
	 [DBName]			VARCHAR(1000)
	,[SchemaName]			VARCHAR(1000)
	,[TableName]			VARCHAR(1000)
	,[RowCount]			BIGINT
	,[TotalSpaceKB]			BIGINT
	,[TotalSpaceMB]			BIGINT
	,[UsedSpaceKB]			BIGINT
	,[UsedSpaceMB]			BIGINT
	,[UnusedSpaceKB]		BIGINT
	,[UnusedSpaceMB]		BIGINT
)
GO

--Collect informations
INSERT INTO #List
EXEC sp_msforeachdb'Use [?]
SELECT 
    DB_NAME() AS DataBaseName,
    s.Name AS SchemaName,
    t.NAME AS TableName,
    p.rows ,
    SUM(a.total_pages) * 8 AS TotalSpaceKB, 
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS TotalSpaceMB,
    SUM(a.used_pages) * 8 AS UsedSpaceKB, 
    CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS UsedSpaceMB, 
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB,
    CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS UnusedSpaceMB
FROM 
    sys.tables t
INNER JOIN      
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255 
GROUP BY 
    t.Name, s.Name, p.Rows
ORDER BY 
    TotalSpaceMB DESC, t.Name'

--Select informations
SELECT * FROM #List ORDER BY DBName,[RowCount] DESC
