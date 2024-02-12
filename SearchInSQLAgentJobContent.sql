USE [msdb]
GO

SELECT 
     [sJOB].[job_id]	AS [JobID]
    ,[sJOB].[name]		AS [JobName]
    ,[step].step_name
    ,[step].command
FROM
    [msdb].[dbo].[sysjobs] AS [sJOB]
    LEFT JOIN [msdb].dbo.sysjobsteps step ON sJOB.job_id = step.job_id

WHERE [step].[command] LIKE '%ENTERSEARCHKEYWORD%'
ORDER BY [JobName]
