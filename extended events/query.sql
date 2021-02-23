ALTER EVENT SESSION [Query] ON SERVER  STATE = stop
go
ALTER EVENT SESSION [Query] ON SERVER  STATE = start
go

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


