USE master
GO

/*set blocked process threshold to 10 seconds*/
sp_configure 'show advanced options', 1 ;
GO
RECONFIGURE ;
GO
sp_configure 'blocked process threshold', 10 ;
GO
RECONFIGURE ;
GO


/*create extended event that will capture blocks and deadlocks*/
CREATE EVENT SESSION [blocked_process] ON SERVER
ADD EVENT sqlserver.blocked_process_report(
    ACTION(sqlserver.client_app_name,
           sqlserver.client_hostname,
           sqlserver.database_name)) ,
ADD EVENT sqlserver.xml_deadlock_report (
    ACTION(sqlserver.client_app_name,
           sqlserver.client_hostname,
           sqlserver.database_name))
ADD TARGET package0.asynchronous_file_target
(SET filename = 'G:\MSSQL\ExtendedEvents\blocked_process.xel',
     metadatafile = 'G:\MSSQL\ExtendedEvents\blocked_process.xem',
     max_file_size=5,
     max_rollover_files=5)
GO

ALTER EVENT SESSION [blocked_process] ON SERVER STATE = start
GO



SET QUOTED_IDENTIFIER ON
GO

/*query to return blocked processes to be run from a sql agent job*/
SELECT
	[XML Data].value('(/event[@name=''blocked_process_report'']/@timestamp)[1]','DATETIME2(2)') AS [TimeStamp],
	[XML Data].value('(/event/data[@name=''database_name'']/value)[1]','SYSNAME') AS [Database Name],
	[XML Data].value('(/event/data[@name=''transaction_id'']/value)[1]','SYSNAME') AS transaction_id,
	[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocked-process/process/@clientapp)[1]','SYSNAME') AS blocked_clientapp,
	[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocked-process/process/inputbuf)[1]','SYSNAME') AS blocked_query,	
	[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocking-process/process/@clientapp)[1]','SYSNAME') AS blocking_clientapp,
	[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocking-process/process/@hostname)[1]','SYSNAME') AS blocking_hostname,
	[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocking-process/process/inputbuf)[1]','SYSNAME') AS blocking_query
INTO ##Blocked
FROM
	(
	SELECT	CONVERT(XML, event_data) AS [XML Data]
	FROM 
		sys.fn_xe_file_target_read_file
		('G:\MSSQL\ExtendedEvents\blocked_process*.xel',
		'G:\MSSQL\ExtendedEvents\blocked_process*.xem',
		null, null)
	WHERE CONVERT(XML, event_data).value('(/event[@name=''blocked_process_report'']/@timestamp)[1]','DATETIME2(2)') > DATEADD(MINUTE, -1, GETUTCDATE())
	) AS v
ORDER BY [TimeStamp] DESC


IF EXISTS (SELECT * FROM ##Blocked)
BEGIN
	DECLARE @tableHTML NVARCHAR(MAX)
	SET @tableHTML =
		N'<table border="1">' +
		N'<tr><th>Time</th><th>DB</th>' +
		N'<th>TransactionID</th><th>BlockedClientApp</th>' +
		N'<th>BlockedQuery</th>' +
		N'<th>BlockingClientApp</th>' +
		N'<th>BlockingHostp</th>' +
		N'<th>BlockingQuery</th>' +

		CAST ( ( SELECT td = [TimeStamp], '',
						td = [Database Name], '',
						td = transaction_id, '',
						td = blocked_clientapp, '',
						td = blocked_query, '',
						td = blocking_clientapp, '',
						td = blocking_hostname, '',
						td = blocking_query, ''
				 FROM 
					(
					SELECT [TimeStamp], [Database Name], transaction_id, blocked_clientapp, blocked_query, blocking_clientapp, blocking_hostname, blocking_query FROM ##Blocked
					) a
				order by [TimeStamp] desc
				  FOR XML PATH('tr'), TYPE 
		) AS NVARCHAR(MAX) ) +
		N'</table>' ;

			exec  msdb.dbo.sp_send_dbmail 
			@profile_name ='Server Notifications',
			@recipients = 'TJGDLTotalJobsOps-DBAs@totaljobsgroup.com',
			@Subject = 'Blocked Processes',
			@body_format ='HTML',
			@body = @tableHTML
END

DROP TABLE ##Blocked