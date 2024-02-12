/*
-----------------------------------------------@kisinamso-----------------------------------------------
|Database sizes for a instance. You can see MB or GB also you can modified different measure size.     |
-----------------------------------------------@kisinamso-----------------------------------------------
*/
SELECT
	 SERVERPROPERTY('MachineName') AS ServerName
	,d.NAME AS DatabaseName
    	,ROUND(SUM(CAST(mf.size AS bigint)) * 8 / 1024, 0) Size_MBs
    	,(SUM(CAST(mf.size AS bigint)) * 8 / 1024) / 1024 AS Size_GBs
FROM sys.master_files mf
INNER JOIN sys.databases d ON d.database_id = mf.database_id
WHERE d.database_id > 4 -- Skip system databases if you want
and d.is_read_only = 0
GROUP BY d.NAME
ORDER BY d.NAME 
