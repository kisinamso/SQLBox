/*
-----------------------------------------------@kisinamso-----------------------------------------------
|In my idea this is very amazing backup chain and database restore generator script. 			|
|Backup chain never break this is very important.							|
|You can use for new AG replica or HA solutions.							|
|I explained to below work to do. 									|
|You just set the variables according the comments then enjoy the result.   				|
-----------------------------------------------@kisinamso-----------------------------------------------
*/
SET NOCOUNT ON;
--Drop temp table if exists.
IF OBJECT_ID('tempdb..#Backups','U') IS NOT NULL DROP TABLE #Backups;
IF OBJECT_ID('tempdb..#BackupFiles','U') IS NOT NULL DROP TABLE #BackupFiles;

/*
	SET THE VARIABLES BELOW!
*/

--Set the database name for backup.
DECLARE  @DatabaseName			VARCHAR(100) = 'ENTER DB NAME'
	
--If there is a place in the source directory that needs to be changed, please specify it. If not, you can leave it blank, but not null!
DECLARE  @ChangeSourceForDBRestorePath	VARCHAR(MAX) = 'ENTER SOURCE FULL BACKUP PATH'
	
--If there is a place in the target directory that needs to be changed, please specify it. If not, you can leave it blank, but not null!
DECLARE  @ChangeTargetForDBRestorePath	VARCHAR(MAX) = 'ENTER TARGET FULL BACKUP PATH'

--If there is a place in the source directory that needs to be changed, please specify it. If not, you can leave it blank, but not null!
DECLARE  @ChangeSourceForLogRestorePath	VARCHAR(MAX) = 'ENTER SOURCE LOG BACKUP PATH'

--If there is a place in the target directory that needs to be changed, please specify it. If not, you can leave it blank, but not null!
DECLARE  @ChangeTargetForLogRestorePath	VARCHAR(MAX) = 'ENTER TARGET LOG BACKUP PATH'

--Restore recovery mode. 
DECLARE  @RecoveryType			VARCHAR(50)  = 'NORECOVERY'

--Restore completion status sequence number.
DECLARE  @Stats				INT	     = 5

--Calculating backup count.
DECLARE  @BackupCount			INT	

/*
	HAVE FUN WHILE WAITING FOR THE QUERY RESULTS :)
*/
CREATE TABLE #Backups (
    BakID                  INTEGER IDENTITY(1, 1) NOT NULL PRIMARY KEY,
    database_name          SYSNAME,
    backup_set_id          INTEGER NOT NULL,
    media_set_id           INTEGER NOT NULL,
    first_family_number    TINYINT NOT NULL,
    last_family_number     TINYINT NOT NULL,
    first_lsn              NUMERIC(25, 0) NULL,
    last_lsn               NUMERIC(25, 0) NULL,
    database_backup_lsn    NUMERIC(25, 0) NULL,
    backup_finish_date     DATETIME NULL,
    type                   CHAR(1) NULL,
    family_sequence_number TINYINT NOT NULL,
    physical_device_name   NVARCHAR(260) NOT NULL,
    device_type            TINYINT NULL,
    position               INTEGER NULL,
    is_backup_chain_broken BIT NOT NULL DEFAULT 0,
    is_backup_file_present BIT NOT NULL DEFAULT 0,
    physical_path_name     NVARCHAR(260) NULL,
    physical_file_name     NVARCHAR(260)
);
CREATE INDEX IX1 ON #Backups (database_name, database_backup_lsn);
CREATE INDEX IX2 ON #Backups ([type], database_name, last_lsn);
CREATE INDEX IX3 ON #Backups (database_name, last_lsn);
CREATE INDEX IX4 ON #Backups (database_name, [type]) INCLUDE (first_lsn, last_lsn);
CREATE INDEX IX5 ON #Backups (physical_path_name) INCLUDE (physical_file_name, BakID);
 
-- Get the most recent full backup with all backup files
WITH cte AS
(
SELECT  B.database_name,
        B.backup_set_id,
        B.media_set_id,
        B.first_family_number,
        B.last_family_number,
        B.first_lsn,
        B.last_lsn,
        B.database_backup_lsn,
        B.backup_finish_date,
        B.type,
        B.position,
        BF.family_sequence_number,
        BF.physical_device_name,
        BF.device_type,
        RN = ROW_NUMBER() 
             OVER (PARTITION BY B.database_name
                       ORDER BY B.backup_finish_date DESC, B.backup_set_id)
FROM    msdb.dbo.backupset AS B
        JOIN msdb.dbo.backupmediafamily AS BF
            ON  BF.media_set_id = B.media_set_id
            AND BF.family_sequence_number BETWEEN B.first_family_number
                                          AND     B.last_family_number
 
WHERE   B.is_copy_only = 0
AND     B.type = 'D' -- FULL database backup
AND     BF.physical_device_name NOT IN ('Nul', 'Nul:')
AND     BF.device_type <> 7 -- virtual device type - can you restore from one of these?
)
INSERT  INTO #Backups (
        database_name,
        backup_set_id,
        media_set_id,
        first_family_number,
        last_family_number,
        first_lsn,
        last_lsn,
        database_backup_lsn,
        backup_finish_date,
        type,
        position,
        family_sequence_number,
        physical_device_name,
        device_type,
        physical_path_name,
        physical_file_name)
SELECT  database_name,
        backup_set_id,
        media_set_id,
        first_family_number,
        last_family_number,
        first_lsn,
        last_lsn,
        database_backup_lsn,
        backup_finish_date,
        type,
        position,
        family_sequence_number,
        physical_device_name,
        device_type,
        REVERSE(SUBSTRING(ca.rfile, ISNULL(NULLIF(CHARINDEX('\', ca.rfile),0),1), 8000)),
		REVERSE(LEFT(ca.rfile, ISNULL(NULLIF(CHARINDEX('\', ca.rfile)-1, -1), LEN(ca.rfile))))
FROM    cte
        CROSS APPLY (SELECT rfile = REVERSE(physical_device_name)) ca
WHERE   RN = 1;
 
-- Get the most recent differential backup based on that full backup
WITH cte AS
(
SELECT  B.database_name,
        B.backup_set_id,
        B.media_set_id,
        B.first_family_number,
        B.last_family_number,
        B.first_lsn,
        B.last_lsn,
        B.database_backup_lsn,
        B.backup_finish_date,
        B.type,
        B.position,
        BF.family_sequence_number,
        BF.physical_device_name,
        BF.device_type,
        RN = ROW_NUMBER() 
             OVER (PARTITION BY B.database_name
                       ORDER BY B.backup_finish_date DESC, B.backup_set_id)
FROM    msdb.dbo.backupset AS B
        JOIN #Backups baks
            ON  baks.database_name = B.database_name
-- Get the lsn that the differential backups, if any, will be based on
            AND baks.database_backup_lsn = B.database_backup_lsn
        JOIN msdb.dbo.backupmediafamily AS BF
            ON  BF.media_set_id = B.media_set_id
            AND BF.family_sequence_number BETWEEN B.first_family_number
                                          AND     B.last_family_number
 
WHERE   B.is_copy_only = 0
AND     B.type = 'I' -- DIFFERENTIAL database backup
AND     BF.physical_device_name NOT IN ('Nul', 'Nul:')
)
INSERT  INTO #Backups(
        database_name,
        backup_set_id,
        media_set_id,
        first_family_number,
        last_family_number,
        first_lsn,
        last_lsn,
        database_backup_lsn,
        backup_finish_date,
        type,
        position,
        family_sequence_number,
        physical_device_name,
        device_type,
        physical_path_name,
        physical_file_name)
SELECT  database_name,
        backup_set_id,
        media_set_id,
        first_family_number,
        last_family_number,
        first_lsn,
        last_lsn,
        database_backup_lsn,
        backup_finish_date,
        type,
        position,
        family_sequence_number,
        physical_device_name,
        device_type,
        REVERSE(SUBSTRING(ca.rfile, ISNULL(NULLIF(CHARINDEX('\', ca.rfile),0),1), 8000)),
		REVERSE(LEFT(ca.rfile, ISNULL(NULLIF(CHARINDEX('\', ca.rfile)-1, -1), LEN(ca.rfile))))
FROM    cte
        CROSS APPLY (SELECT rfile = REVERSE(physical_device_name)) ca
WHERE   RN = 1;
 
-- Get all log backups where the last_lsn is >= the last_lsn for this db's full/diff b/u.
WITH cte AS 
(
SELECT  database_name, last_lsn = MAX(last_lsn)
FROM    #Backups
GROUP BY database_name
)
INSERT  INTO #Backups (
        database_name,
        backup_set_id,
        media_set_id,
        first_family_number,
        last_family_number,
        first_lsn,
        last_lsn,
        database_backup_lsn,
        backup_finish_date,
        type,
        position,
        family_sequence_number,
        physical_device_name,
        device_type,
        physical_path_name,
        physical_file_name)
SELECT  B.database_name,
        B.backup_set_id,
        B.media_set_id,
        B.first_family_number,
        B.last_family_number,
        B.first_lsn,
        B.last_lsn,
        B.database_backup_lsn,
        B.backup_finish_date,
        B.type,
        B.position,
        BF.family_sequence_number,
        BF.physical_device_name,
        BF.device_type,
        REVERSE(SUBSTRING(ca.rfile, ISNULL(NULLIF(CHARINDEX('\', ca.rfile),0),1), 8000)),
		REVERSE(LEFT(ca.rfile, ISNULL(NULLIF(CHARINDEX('\', ca.rfile)-1, -1), LEN(ca.rfile))))
FROM    msdb.dbo.backupset B
        JOIN cte baks
            ON  baks.database_name = B.database_name
            AND baks.last_lsn <= B.last_lsn
        JOIN msdb.dbo.backupmediafamily AS BF
            ON  BF.media_set_id = B.media_set_id
            AND BF.family_sequence_number BETWEEN B.first_family_number
                                          AND     B.last_family_number
        CROSS APPLY (SELECT rfile = REVERSE(BF.physical_device_name)) ca
WHERE   B.is_copy_only = 0
AND     B.type = 'L' -- Transaction Log backups
AND     BF.physical_device_name NOT IN ('Nul', 'Nul:')
--AND     @DBBackupLSN BETWEEN B.first_lsn AND B.last_lsn
ORDER BY B.database_name, B.last_lsn, B.backup_finish_date, B.backup_set_id;
 
-- mark any tlogs if the log backup chain is broken
-- this only marks the one that is immediately after the break
-- if you desire, you can delete this and the following to only show the recoverable files
WITH cte (database_name, last_lsn) AS 
(
-- get the latest lsn that is in a full/diff backup per database
SELECT  database_name, MAX(last_lsn)
FROM    #Backups
WHERE   type LIKE '[DI]'
GROUP BY database_name
), cte2 (database_name, BakID) AS
(
-- get any log backups where:
-- 1. that backups first_lsn is not equal to a last_lsn for another log backup (should be the previous backup)
-- 2. that backup is not the first log backup, where the max from the full/diff will be between it's first_lsn / last_lsn 
SELECT  t1.database_name, MIN(t1.BakID)
FROM    #Backups t1
        LEFT JOIN cte 
            ON  cte.database_name = t1.database_name
WHERE   t1.type = 'L'
AND     t1.first_lsn NOT IN (SELECT last_lsn FROM #Backups t2 WHERE t1.database_name = t2.database_name AND type = 'L')
AND     cte.last_lsn NOT BETWEEN t1.first_lsn AND t1.last_lsn
GROUP BY t1.database_name
)
UPDATE  t1
SET     is_backup_chain_broken = 1
FROM    #Backups t1
        JOIN cte2 
            ON  t1.database_name = cte2.database_name
            AND t1.BakID = cte2.BakID;
 
-- get each unique directory that the backup files were created in
-- For each directory, 
--  get list of all of the files in the directory
--  check for missing backup files
CREATE TABLE #BackupFiles (
    BackupFilesID INTEGER IDENTITY PRIMARY KEY NONCLUSTERED,
    subdirectory  NVARCHAR(260),
    depth         SMALLINT,
    is_file       BIT,
    UNIQUE CLUSTERED (subdirectory, BackupFilesID)
);
 
DECLARE @physical_path_name NVARCHAR(260), @cmd NVARCHAR(1000);
DECLARE cFilePaths CURSOR FAST_FORWARD READ_ONLY FOR
SELECT  DISTINCT physical_path_name
FROM    #Backups;
 
OPEN cFilePaths
 
FETCH NEXT FROM cFilePaths INTO @physical_path_name;
 
WHILE @@FETCH_STATUS = 0
BEGIN
    TRUNCATE TABLE #BackupFiles;
 
    -- get the list of files in this directory, put into temp table.
    SET @cmd = N'EXECUTE xp_dirtree N''' + @physical_path_name + N''',1,1;';
    INSERT INTO #BackupFiles EXECUTE (@cmd);
 
    -- update the files that are present
    UPDATE  t1
    SET     is_backup_file_present = 1
    FROM    #Backups t1
            JOIN #BackupFiles t2 ON t1.physical_file_name = t2.subdirectory
    WHERE   t1.physical_path_name = @physical_path_name
    FETCH NEXT FROM cFilePaths INTO @physical_path_name;
END
 
CLOSE cFilePaths;
DEALLOCATE cFilePaths;
 
 SET @BackupCount =  (SELECT COUNT(1) FROM	#Backups WHERE database_name = @DatabaseName)

SELECT	 type
		--,ROW_NUMBER() over (ORDER  BY backup_finish_date )
		,backup_finish_date
		,first_lsn
		,last_lsn
		,database_backup_lsn
		--,physical_device_name
		--,physical_path_name
		,CASE type
      WHEN 'D' THEN 'RESTORE DATABASE ' + QUOTENAME(database_name) + ' FROM DISK = ''' + REPLACE(physical_device_name,@ChangeSourceForDBRestorePath, @ChangeTargetForDBRestorePath)  + ''' WITH  ' + @RecoveryType + ', STATS = ' + CAST(@Stats AS VARCHAR(10)) + ', NOUNLOAD, FILE = 1' + ';PRINT(' + CAST(ROW_NUMBER() OVER (ORDER  BY backup_finish_date ) AS VARCHAR(100)) + '/ ' + CAST(@BackupCount  AS VARCHAR(100))+ ')'
      WHEN 'L' THEN 'RESTORE LOG '		+ QUOTENAME(database_name) + ' FROM DISK = ''' + REPLACE(physical_device_name,@ChangeSourceForLogRestorePath,@ChangeTargetForLogRestorePath) + ''' WITH  ' + @RecoveryType + ', NOUNLOAD, FILE = 1'  + CAST(@Stats AS VARCHAR(10)) + ', NOUNLOAD, FILE = 1' + ';PRINT(' + CAST(ROW_NUMBER() over (ORDER  BY backup_finish_date ) AS VARCHAR(100)) + '/ ' + CAST(@BackupCount AS VARCHAR(100))+ ')'
      END AS SCRIPT
FROM	#Backups
WHERE database_name = @DatabaseName
ORDER BY database_name, BakID;
