/*
-----------------------------------------------@kisinamso-----------------------------------------------
|This stored procedure returns the disables or enables all triggers in is a                             |
|database which your specified database.					                                                      |
-----------------------------------------------@kisinamso-----------------------------------------------
*/
USE [master]
GO
CREATE OR ALTER PROCEDURE sp_TriggerEnableDisable
(
--0 : For Enable
--1 : For Disable
  @Type TINYINT 
 ,@DatabaseName SYSNAME 
)
AS

BEGIN
DECLARE @sql NVARCHAR(MAX) 
DROP TABLE IF EXISTS #Script
CREATE TABLE #Script
(
	 DatabaseName VARCHAR(500)
	,Script NVARCHAR(MAX)
)

SET @sql = 
'
USE [?];
--0 : For Enable
--1 : For Disable
DECLARE @Type  TINYINT = ' + CAST(@Type AS VARCHAR(5)) + '

IF  @Type = 0
BEGIN

SELECT 
DB_NAME(),
	CASE 
	--OBJECT OR COLUMN TRIGGER
	WHEN parent_class = 1
	THEN CAST(''ENABLE TRIGGER [dbo].'' + QUOTENAME(name) + '' ON [dbo].'' + OBJECT_NAME(parent_id) + '';'' AS VARCHAR(MAX))
	--DATABASE TRIGGER
	WHEN parent_class = 0
	THEN CAST(''ENABLE TRIGGER '' + QUOTENAME(name) + '' ON DATABASE'' AS VARCHAR(MAX))
	END AS EnableScript
FROM sys.triggers WHERE is_disabled = 1

END	

ELSE IF @Type = 1
BEGIN

	SELECT 
	DB_NAME(),
	CASE 
	--OBJECT OR COLUMN TRIGGER
	WHEN parent_class = 1
	THEN CAST(''DISABLE TRIGGER [dbo].'' + QUOTENAME(name) + '' ON [dbo].'' + OBJECT_NAME(parent_id) + '';'' AS VARCHAR(MAX))
	--DATABASE TRIGGER
	WHEN parent_class = 0
	THEN CAST(''DISABLE TRIGGER '' + QUOTENAME(name) + '' ON DATABASE'' AS VARCHAR(MAX))
	END AS DisableScript
FROM sys.triggers WHERE is_disabled = 0

END

ELSE
BEGIN
	SELECT DB_NAME(), ''Please enter 0 or 1! Your value is:'' ' + CAST(@Type AS VARCHAR(5)) + '
END
'

INSERT INTO #Script

EXEC sp_MSforeachdb @SQL

SELECT 'USE ' + QUOTENAME(DatabaseName) + '; ' + Script FROM #Script  WHERE DatabaseName = @DatabaseName

END
