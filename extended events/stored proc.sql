DROP EVENT SESSION [monitor_procedure_performance] ON SERVER 
GO

CREATE EVENT SESSION [monitor_procedure_performance] ON SERVER
ADD EVENT sqlserver.rpc_completed 
    ( 
        ACTION    (package0.collect_system_time,package0.process_id,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text)
        WHERE    ([object_name]='up_JobMatch_Select') 
    )
	, 
ADD EVENT sqlserver.sp_statement_completed 
    ( 
        ACTION    (package0.collect_system_time,package0.process_id,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text)
        WHERE    ([object_id] = 284871553)
    )
ADD TARGET package0.asynchronous_file_target
(SET filename = 'G:\MSSQL\ExtendedEvents\monitor_procedure_performance.xel',
     metadatafile = 'G:\MSSQL\ExtendedEvents\monitor_procedure_performance.xem',
     max_file_size=5,
     max_rollover_files=3)
WITH (MAX_DISPATCH_LATENCY = 5SECONDS);
GO

ALTER EVENT SESSION [monitor_procedure_performance] ON SERVER
STATE = START
GO






SET QUOTED_IDENTIFIER ON
GO

/*query to return logged data*/
SELECT
	[XML Data],
	[XML Data].value('(event/@timestamp)[1]',   'datetime2') AS [eventtime] ,
	[XML Data].value('(event/action[@name="client_app_name"]/value)[1]', 'nvarchar(128)')          AS [client app name],
	[XML Data].value('(event/action[@name="client_hostname"]/value)[1]', 'nvarchar(max)')          AS [client host name],
	[XML Data].value('(event/action[@name="database_name"]/value)[1]', 'nvarchar(max)')          AS [database name],
	[XML Data].value('(event/data[@name="duration"]/value)[1]', 'bigint')          AS [duration (ms)],
	[XML Data].value('(event/data[@name="cpu_time"]/value)[1]', 'bigint')          AS [cpu time (ms)],
	[XML Data].value('(event/data[@name="logical_reads"]/value)[1]', 'bigint') AS [logical reads],
	[XML Data].value('(event/data[@name="physical_reads"]/value)[1]', 'bigint') AS [physical_reads],
	[XML Data].value('(event/data[@name="writes"]/value)[1]', 'bigint') AS writes,
	[XML Data].value('(event/data[@name="statement"]/value)[1]', 'nvarchar(max)') AS statement
FROM
	(
	SELECT CONVERT(XML, event_data) AS [XML Data]
	FROM 
		sys.fn_xe_file_target_read_file
         ('G:\MSSQL\ExtendedEvents\monitor_procedure_performance*.xel',
          'G:\MSSQL\ExtendedEvents\monitor_procedure_performance*.xem',
		null, null)
	--WHERE CONVERT(XML, event_data).value('(event/@timestamp)[1]',   'datetime2') > '2015-10-08 09:05:00'
	) AS v
ORDER BY [eventtime]

