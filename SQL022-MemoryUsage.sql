USE DB_NAME
GO
SELECT
--[DatabaseName] = CASE [database_id] WHEN 32767
--THEN 'Resource DB'
--ELSE DB_NAME([database_id]) END,
COUNT_BIG(*) [Pages in Buffer],
COUNT_BIG(*)/128 [Buffer Size in MB]
FROM sys.dm_os_buffer_descriptors
--GROUP BY [database_id]
--ORDER BY [Pages in Buffer] DESC;
