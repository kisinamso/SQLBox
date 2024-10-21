USE DB_NAME
GO
SELECT db
,file_group
,SUM(sizeGB) sum_sizeGB
,SUM(space_usedGB) sum_space_UsedGB
,SUM(free_spaceGB) sum_free_spaceGB
,ROUND((SUM(space_usedGB) / SUM(sizeGB)) * 100, 2) sum_pct_used
FROM (
SELECT DB_NAME() db
,ISNULL(fg.name, 'LOG') AS file_group
,ROUND(SUM(cast(f.size AS FLOAT) / (128 * 1024)), 2) AS sizeGB
,ROUND(SUM(cast(FILEPROPERTY(f.name, 'spaceused') AS FLOAT) / (128 * 1024)), 2) space_usedGB
,ROUND((SUM(f.size - cast(FILEPROPERTY(f.name, 'spaceused') AS FLOAT)) / (128 * 1024)), 2) free_spaceGB
,ROUND((SUM(CAST(FILEPROPERTY(f.name, 'spaceused') AS FLOAT))) / ISNULL(SUM(cast(f.size AS FLOAT)), 0) * 100, 2) AS [pct_used]
FROM sys.database_files f
LEFT JOIN sys.filegroups fg ON f.data_space_id = fg.data_space_id
WHERE ISNULL(fg.name, 'LOG') NOT LIKE 'memory_optimized%'
GROUP BY fg.name
) a
GROUP BY db
,file_group

------------------------
SELECT
    db.name AS DBName,
    type_desc AS FileType,
    mf.name AS DataFileName,
    Physical_Name AS Location
FROM
    sys.master_files mf
INNER JOIN 
    sys.databases db ON db.database_id = mf.database_id 
	where db.name = DB_NAME()
