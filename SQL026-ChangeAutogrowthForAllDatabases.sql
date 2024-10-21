DECLARE @DataFileMB INT = 64
DECLARE @LogFileMB INT = 10
SET @DataFileMB = @DataFileMB * 1024
SET @LogFileMB = @LogFileMB * 1024

SELECT CASE 
WHEN type_desc = 'ROWS' THEN
'ALTER DATABASE ' + QUOTENAME(db.name) +' MODIFY FILE ( NAME = N''' + mf.name + ''', FILEGROWTH = ' + CAST(@DataFileMB AS VARCHAR) + 'KB )' 
WHEN type_desc = 'LOG' THEN 
'ALTER DATABASE ' + QUOTENAME(db.name) +' MODIFY FILE ( NAME = N''' + mf.name + ''', FILEGROWTH = ' + CAST(@LogFileMB  AS VARCHAR) + 'KB )'
END AS Script --,
    --db.name AS DBName,
    --type_desc AS FileType,
    --mf.name AS DataFileName,
    --Physical_Name AS Location
FROM
    sys.master_files mf
INNER JOIN 
    sys.databases db ON db.database_id = mf.database_id 
