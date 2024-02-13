/*
-----------------------------------------------@kisinamso-----------------------------------------------
|This script returns SQL Server which year, Security Package, Cumulative Update Level,Version infos    |
-----------------------------------------------@kisinamso-----------------------------------------------
*/
SELECT 
			 CASE SUBSTRING(CONVERT(VARCHAR(50), SERVERPROPERTY('ProductVersion')), 1, 2)
						WHEN '8.' THEN '2000'
						WHEN '9.' THEN '2005'
						WHEN '10' THEN '2008'
						WHEN '11' THEN '2012'
						WHEN '12' THEN '2014'
						WHEN '13' THEN '2016'
						WHEN '14' THEN '2017'
						WHEN '15' THEN '2019'
						WHEN '16' THEN '2022'
				 END AS YEAR_
			,SERVERPROPERTY ('ProductLevel') AS SP  
			,SERVERPROPERTY('ProductUpdateLevel') AS 'ProductUpdateLevel'
			,SERVERPROPERTY('ProductVersion') AS Version
			,@@VERSION AS [Current Version]
