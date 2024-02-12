/*
-----------------------------------------------@kisinamso-----------------------------------------------
| Create a login and giving database role to it.                                                        |
-----------------------------------------------@kisinamso-----------------------------------------------
*/

--STEP 1 : Create the Login(Windows or SQL) which needs the db_datareader access.

--create login [doamin\username] from windows;
CREATE LOGIN [X] WITH PASSWORD = 0x1 HASHED;
ALTER  LOGIN  [X] WITH CHECK_POLICY = ON, CHECK_EXPIRATION = ON;

--Step 2:  Replace the user with the one that requires access in Set @user in parameters below


USE master
GO


DECLARE @DatabaseName NVARCHAR(100)   
DECLARE @SQL NVARCHAR(max)
DECLARE @User VARCHAR(64)
SET @User = '[X]' --Replace Your User here

DECLARE Grant_Permission CURSOR LOCAL FOR
SELECT name FROM sys.databases
WHERE --name NOT IN ('master','model','msdb','tempdb','distribution')  
--and
[state_desc]='ONLINE' and  [is_read_only] <> 1 order by name
OPEN Grant_Permission  
FETCH NEXT FROM Grant_Permission INTO @DatabaseName  
WHILE @@FETCH_STATUS = 0  

BEGIN  

SELECT @SQL = 'USE '+ '[' + @DatabaseName + ']' +'; '+ 'CREATE USER ' + @User + 
    'FOR LOGIN ' + @User + '; EXEC sp_addrolemember N''db_datareader'', 
    ' + @User + '';
PRINT @SQL
EXEC sp_executesql @SQL

Print ''-- This is to give a line space between two databases execute prints.

FETCH NEXT FROM Grant_Permission INTO @DatabaseName  
  
END  

CLOSE Grant_Permission  
DEALLOCATE Grant_Permission
