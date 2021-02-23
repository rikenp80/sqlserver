/*
CREATE EVENT SESSION [page_splits] ON SERVER 
ADD EVENT sqlserver.page_split(
    ACTION(sqlserver.sql_text))
ADD TARGET package0.event_file(SET filename=N'D:\XE\page_splits',max_file_size=(1024),max_rollover_files=(25))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
GO

ALTER EVENT SESSION page_splits ON SERVER STATE = START

*/



use eWFM_P_WFMCC
GO

--drop table [dbManagement].[dbo].[PageSplits]
--go

insert into [dbManagement].[dbo].[PageSplits]
select b.*, o.name 'table', i.name 'index'
--into [dbManagement].[dbo].[PageSplits]
from
	(
	SELECT	xml_data,
			xml_data.value('(/event[@name=''page_split'']/@timestamp)[1]','datetime') 'timestamp',
			xml_data.value('(/event/data[@name=''file_id'']/value)[1]','int') 'FileID',
			--xml_data.value('(/event/data[@name=''page_id'']/value)[1]','int') 'PageID',
			--xml_data.value('(/event/data[@name=''new_page_page_id'']/value)[1]','int') 'NewPageID',
			xml_data.value('(/event/data[@name=''rowset_id'']/value)[1]','bigint') 'rowset_id',
			xml_data.value('(/event/data[@name=''database_id'']/value)[1]','int') 'DBID',
			xml_data.value('(/event/action[@name=''sql_text'']/value)[1]','nvarchar(max)') 'sql',
			xml_data.value('(/event/data[@name=''splitOperation'']/text)[1]','varchar(50)') 'splitOperation'
	FROM
		(
		SELECT object_name 'event', CONVERT(xml, event_data) 'xml_data'
		FROM sys.fn_xe_file_target_read_file ('D:\XE\page_splits_0_132273907401540000.xel', null, NULL, NULL)
		) AS a
	) b
	left join sys.partitions p on p.hobt_id = b.rowset_id
	left join sysobjects o on p.object_id = o.id
	left join sys.indexes i on p.index_id = i.index_id and o.id = i.object_id
where b.DBID = DB_ID('eWFM_P_WFMCC')





--Query
--select count(*) from [dbManagement].[dbo].[PageSplits] (nolock)
--select top 100 * from [dbManagement].[dbo].[PageSplits] (nolock)

select	
	min(timestamp) 'min_timestamp',
	max(timestamp) 'max_timestamp',
	datediff(MINUTE, min(timestamp), max(timestamp)) 'timespan',
	splitOperation,
	[table],
	[index],
	count(*) 'splits',
	count(*)/(case when (datediff(MINUTE, min(timestamp), max(timestamp))) = 0 then 1 else (datediff(MINUTE, min(timestamp), max(timestamp))) end) 'splits/min'
from [dbManagement].[dbo].[PageSplits] (nolock)
group by 
	splitOperation,
	[table],
	[index]
having count(*) > 1	
	and count(*)/(case when (datediff(MINUTE, min(timestamp), max(timestamp))) = 0 then 1 else (datediff(MINUTE, min(timestamp), max(timestamp))) end) > 1 --splits/min greater than 1
	and datediff(MINUTE, min(timestamp), max(timestamp)) > 1 --over a time period of more than a minute
order by 
	splits desc


select
	splitOperation,
	[index],
	count(*) 'splits',
	count(*)/(case when (datediff(MINUTE, min(timestamp), max(timestamp))) = 0 then 1 else (datediff(MINUTE, min(timestamp), max(timestamp))) end) 'splits/min'
from [dbManagement].[dbo].[PageSplits] (nolock)
where [table] = 'RQS_DATE'
group by 
	splitOperation,
	[index]
order by 
	splits desc


select
	[table],
	[index],
	count(*) 'splits'
from [dbManagement].[dbo].[PageSplits] (nolock)
group by 
	[table],[index]
order by 
	splits desc