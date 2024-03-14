/*
-----------------------------------------------@kisinamso-----------------------------------------------
|This server trigger create directory for backups                                                      |
|If you added new databases this trigger will create new sub directories.			       |
-----------------------------------------------@kisinamso-----------------------------------------------
*/
USE [master]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   TRIGGER [BackupPathCreate] 
ON ALL SERVER 
FOR CREATE_DATABASE 
AS 
    DECLARE 
         @DatabaseName		NVARCHAR(128)
        ,@SQL					NVARCHAR(4000);

    SELECT @DatabaseName = EVENTDATA().value('(/EVENT_INSTANCE/DatabaseName)[1]','NVARCHAR(128)')

--Creating sub directories for databases on a server
--Yearly --> Preview: \\BackupPath\Yearly\ServerName\DatabaseName
    SET @SQL = '
        declare @Path varchar(500) 
		set @Path = ''\\BackupPath\Yearly\' + CAST(@@SERVERNAME AS VARCHAR) + '\' + @DatabaseName + '''
         EXEC master.dbo.xp_create_subdir @Path
		  ';
    EXEC (@SQL);

--Monthly --> Preview: \\BackupPath\Monthly\ServerName\DatabaseName
	    SET @SQL = '
        declare @Path varchar(500) 
		set @Path = ''\\BackupPath\Monthly\' + CAST(@@SERVERNAME AS VARCHAR) + '\' + @DatabaseName + '''
         EXEC master.dbo.xp_create_subdir @Path
		  ';
    EXEC (@SQL);

--Daily --> Preview: \\BackupPath\Daily\ServerName\DatabaseName
	    SET @SQL = '
        declare @Path varchar(500) 
		set @Path = ''\\BackupPath\Daily\' + CAST(@@SERVERNAME AS VARCHAR) + '\' + @DatabaseName + '''
         EXEC master.dbo.xp_create_subdir @Path
		  ';
    EXEC (@SQL);

GO

ENABLE TRIGGER [BackupPathCreate] ON ALL SERVER
GO

