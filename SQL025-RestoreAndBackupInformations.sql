SELECT 
		session_id as SPID, 
		command, 
		a.text AS Query, 
		start_time, 
		DATEDIFF(SECOND,start_time,GETDATE()) as SessionTime,
		percent_complete, 
		DATEADD(SECOND,estimated_completion_time/1000, GETDATE()) as estimated_completion_time, 
		r.wait_type
FROM sys.dm_exec_requests r CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) a 
WHERE r.command in ('BACKUP DATABASE','RESTORE DATABASE','BACKUP LOG','RESTORE LOG')  
