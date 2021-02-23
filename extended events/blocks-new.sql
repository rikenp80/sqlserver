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


drop table [dbManagement].[dbo].[Blocking]
go

--insert into [dbManagement].[dbo].[Blocking]
select *
into [dbManagement].[dbo].[Blocking]
from
	(
	SELECT
	[XML Data],
	[XML Data].value('(/event[@name=''blocked_process_report'']/@timestamp)[1]','DATETIME2(2)') AS [TimeStamp],
	[XML Data].value('(/event/data[@name=''database_name'']/value)[1]','SYSNAME') AS [Database Name],
	([XML Data].value('(/event/data[@name=''duration'']/value)[1]','BIGINT'))/1000000.0 AS block_duration_secs,
	[XML Data].value('(/event/data[@name=''lock_mode'']/text)[1]','SYSNAME') AS lock_mode,
	[XML Data].value('(/event/data[@name=''transaction_id'']/value)[1]','SYSNAME') AS transaction_id,

	[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocked-process/process/@currentdbname)[1]','SYSNAME') AS blocked_db,
	[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocked-process/process/@clientapp)[1]','SYSNAME') AS blocked_clientapp,
	[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocked-process/process/@loginname)[1]','SYSNAME') AS blocked_loginname,
	[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocked-process/process/@spid)[1]','SYSNAME') AS blocked_spid,
	[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocked-process/process/@lastbatchstarted)[1]','SYSNAME') AS blocked_lastbatchstarted,
	[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocked-process/process/@lastbatchcompleted)[1]','SYSNAME') AS blocked_lastbatchcompleted,
	[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocked-process/process/@waitresource)[1]','SYSNAME') AS blocked_waitresource,
	([XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocked-process/process/@waittime)[1]','BIGINT'))/1000000.0 AS blocked_waittime,
	[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocked-process/process/@lockMode)[1]','SYSNAME') AS blocked_lockMode,
	[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocked-process/process/inputbuf)[1]','SYSNAME') AS blocked_query,	

	[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocking-process/process/@currentdbname)[1]','SYSNAME') AS blocking_db,
	[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocking-process/process/@clientapp)[1]','SYSNAME') AS blocking_clientapp,
	[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocking-process/process/@loginname)[1]','SYSNAME') AS blocking_loginname,
	[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocking-process/process/@spid)[1]','SYSNAME') AS blocking_spid,
	[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocking-process/process/@lastbatchstarted)[1]','SYSNAME') AS blocking_lastbatchstarted,
	[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocking-process/process/@lastbatchcompleted)[1]','SYSNAME') AS blocking_lastbatchcompleted,
	[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocking-process/process/@waitresource)[1]','SYSNAME') AS blocking_waitresource,
	([XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocking-process/process/@waittime)[1]','BIGINT'))/1000000.0 AS blocking_waittime,
	[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocking-process/process/@lockMode)[1]','SYSNAME') AS blocking_lockMode,
	[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocking-process/process/inputbuf)[1]','SYSNAME') AS blocking_query

	--[XML Data].value('(/event/data[@name=''blocked_process'']/value/blocked-process-report/blocked-process[1]','sysname') as abcd
	FROM
		(
		SELECT	CONVERT(XML, event_data) AS [XML Data]
		FROM 
			sys.fn_xe_file_target_read_file
			('D:\XEvents\Blocking\blocked_process_0_132350836535460000.xel',
			null,null, null)
		) AS a
	) b
where [TimeStamp] is not null



SET QUOTED_IDENTIFIER ON
GO

SELECT 
	[XML Data],
	[XML Data].value('(/event[@name=''xml_deadlock_report'']/@timestamp)[1]','DATETIME2(0)') AS [TimeStamp]
FROM
	(
		SELECT CONVERT(XML, event_data) AS [XML Data]
		FROM sys.fn_xe_file_target_read_file ('D:\XEvents\Blocking\blocked_process_0_132350836535460000.xel',null,null, null)
	) AS v
ORDER BY [TimeStamp] DESC





select top 10 *
from [dbManagement].[dbo].[Blocking]
order by timestamp desc