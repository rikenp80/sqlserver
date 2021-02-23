CREATE EVENT SESSION [Query] ON SERVER 
ADD EVENT sqlserver.sql_batch_completed(SET collect_batch_text=(1)
    ACTION(sqlserver.client_hostname,sqlserver.database_name,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_server_principal_name,sqlserver.username)
    WHERE ([sqlserver].[not_equal_i_sql_unicode_string]([sqlserver].[username],N'replman') AND [sqlserver].[equal_i_sql_unicode_string]([sqlserver].[database_name],N'WFM') AND [duration]>(500000)))
ADD TARGET package0.event_file(SET filename=N'D:\XEvents\QueryBatch.xel',max_rollover_files=(50))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
GO




SET QUOTED_IDENTIFIER ON
GO

SELECT
	[XML Data],
	[XML Data].value('(/event/action[@name=''database_name'']/value)[1]','SYSNAME') AS [database_name],
	[XML Data].value('(/event[@name=''sql_batch_completed'']/@timestamp)[1]','DATETIME2(0)') AS [TimeStamp],
	([XML Data].value('(/event/data[@name=''cpu_time'']/value)[1]','BIGINT'))/1000000.0 AS cpu_time,
	([XML Data].value('(/event/data[@name=''duration'']/value)[1]','BIGINT'))/1000000.0 AS duration,
	[XML Data].value('(/event/data[@name=''physical_reads'']/value)[1]','BIGINT') AS physical_reads,
	[XML Data].value('(/event/data[@name=''logical_reads'']/value)[1]','BIGINT') AS logical_reads,
	[XML Data].value('(/event/data[@name=''writes'']/value)[1]','BIGINT') AS writes,
	[XML Data].value('(/event/data[@name=''spills'']/value)[1]','BIGINT') AS spills,
	[XML Data].value('(/event/data[@name=''row_count'']/value)[1]','BIGINT') AS row_count,
	[XML Data].value('(/event/data[@name=''result'']/value)[1]','SYSNAME') AS result,
	[XML Data].value('(/event/data[@name=''batch_text'']/value)[1]','VARCHAR(MAX)') AS batch_text,
	[XML Data].value('(/event/action[@name=''client_hostname'']/value)[1]','VARCHAR(500)') AS client_hostname,	
	[XML Data].value('(/event/action[@name=''session_id'']/value)[1]','BIGINT') AS session_id,
	[XML Data].value('(/event/action[@name=''server_principal_name'']/value)[1]','VARCHAR(500)') AS server_principal_name,
	[XML Data].value('(/event/action[@name=''session_server_principal_name'']/value)[1]','VARCHAR(500)') AS session_server_principal_name,
	[XML Data].value('(/event/action[@name=''username'']/value)[1]','VARCHAR(500)') AS username
FROM
	(
	SELECT	CONVERT(XML, event_data) AS [XML Data]
	FROM 
		sys.fn_xe_file_target_read_file
		('E:\XEvents\QueryBatch*.xel', null, null, null)
	) AS v
ORDER BY [TimeStamp] DESC







/*
CREATE EVENT SESSION [Query] ON SERVER 
ADD EVENT sqlserver.rpc_completed(SET collect_statement=(1)
    ACTION(package0.collect_system_time,sqlserver.client_hostname,sqlserver.database_id,sqlserver.server_principal_name,sqlserver.sql_text)
    WHERE ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'%(@P1 float,@P2 float,@P3 float)%')))
ADD TARGET package0.event_file(SET filename=N'D:\XE\Query',max_file_size=(200),max_rollover_files=(50))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
GO
*/


--drop table [dbManagement].[dbo].[Query]
--go

insert into [dbManagement].[dbo].[Query]
select *
--into [dbManagement].[dbo].[Query]
from
	(
	SELECT
		[XML Data],
		[XML Data].value('(/event/action[@name=''database_id'']/value)[1]','SYSNAME') AS [database_id],
		([XML Data].value('(/event/data[@name=''cpu_time'']/value)[1]','BIGINT'))/1000000.0 AS cpu_time_secs,
		([XML Data].value('(/event/data[@name=''duration'']/value)[1]','BIGINT'))/1000000.0 AS duration_secs,
		[XML Data].value('(/event/data[@name=''physical_reads'']/value)[1]','BIGINT') AS physical_reads,
		[XML Data].value('(/event/data[@name=''logical_reads'']/value)[1]','BIGINT') AS logical_reads,
		[XML Data].value('(/event/data[@name=''writes'']/value)[1]','BIGINT') AS writes,
		[XML Data].value('(/event/data[@name=''row_count'']/value)[1]','BIGINT') AS row_count,
		[XML Data].value('(/event/data[@name=''result'']/value)[1]','SYSNAME') AS result,
		[XML Data].value('(/event/action[@name=''client_hostname'']/value)[1]','VARCHAR(500)') AS client_hostname,	
		[XML Data].value('(/event/action[@name=''session_id'']/value)[1]','BIGINT') AS session_id,
		[XML Data].value('(/event/action[@name=''collect_system_time'']/value)[1]','DATETIME2(0)') AS collect_system_time,
		[XML Data].value('(/event/action[@name=''server_principal_name'']/value)[1]','VARCHAR(500)') AS server_principal_name,
		[XML Data].value('(/event/action[@name=''sql_text'']/value)[1]','VARCHAR(500)') AS sql_text,
		[XML Data].value('(/event/data[@name=''batch_text'']/value)[1]','VARCHAR(MAX)') AS batch_text,
		[XML Data].value('(/event/data[@name=''statement'']/value)[1]','VARCHAR(MAX)') AS statement
	FROM
		(
		SELECT	CONVERT(XML, event_data) AS [XML Data]
		FROM 
			sys.fn_xe_file_target_read_file
			('D:\XE\Query_0_132327*.xel', null, null, null)
		) AS a
	) b


