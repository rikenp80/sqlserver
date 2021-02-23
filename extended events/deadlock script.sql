SET QUOTED_IDENTIFIER ON
GO

/*query to return blocked processes to be run from a sql agent job*/
SELECT top 10
	[XML Data],
	[XML Data].value('(/event[@name=''xml_deadlock_report'']/@timestamp)[1]','DATETIME2(0)') AS [TimeStamp],
	[XML Data].value('(/event/data[@name=''database_name'']/value)[1]','SYSNAME') AS [Database Name],
	[XML Data].value('(/event/data[@name=''transaction_id'']/value)[1]','SYSNAME') AS transaction_id,
	[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocked-process/process/@clientapp)[1]','SYSNAME') AS blocked_clientapp,
	[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocked-process/process/inputbuf)[1]','SYSNAME') AS blocked_query,	
	[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocking-process/process/@clientapp)[1]','SYSNAME') AS blocking_clientapp,
	[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocking-process/process/@hostname)[1]','SYSNAME') AS blocking_hostname,
	[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocking-process/process/inputbuf)[1]','SYSNAME') AS blocking_query
FROM
	(
	SELECT	CONVERT(XML, event_data) AS [XML Data]
	FROM 
		sys.fn_xe_file_target_read_file
		('E:\MSSQL\MSSQL.MSSQLSERVER.Data\ExtendedEvents\blocked_process*.xel',
		'E:\MSSQL\MSSQL.MSSQLSERVER.Data\ExtendedEvents\blocked_process*.xem',
		null, null)
		WHERE CONVERT(XML, event_data).value('(/event[@name=''xml_deadlock_report'']/@timestamp)[1]','DATETIME2(0)') > '2015-07-14'
	) AS v
ORDER BY [TimeStamp] DESC

