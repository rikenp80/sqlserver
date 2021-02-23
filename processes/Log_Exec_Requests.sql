DROP TABLE master.dbo.Log_Exec_Requests
GO
CREATE TABLE master.dbo.Log_Exec_Requests
(
		[TimeStamp]			datetime2(0)
	,	session_id			smallint
	,	hostname			nvarchar(128)
	,	[program_name]		nvarchar(128)
	,	login_name			nvarchar(128)
	,	[status]			nvarchar(30)
	,	command				nvarchar(32)
	,	start_time			datetime
	,	elapsed_time_secs	int
	,	cpu_time_secs		int
	,	reads				bigint
	,	logical_reads		bigint
	,	writes					bigint
	,	DBName					varchar(500)
	,	[text]					nvarchar(max)
	,	blocking_session_id		smallint
	,	transaction_id			bigint
	,	granted_query_mem_MB	int
	,	dop						int
	,	wait_type				nvarchar(60)
	,	wait_resource			nvarchar(256)
	,	sql_handle				varbinary(64)
	,	plan_handle				varbinary(64)
)
GO
create clustered index CIX_Log_Exec_Requests_TimeStamp on Log_Exec_Requests(TimeStamp) with fillfactor = 99
create index IX_Log_Exec_Requests_start_time on Log_Exec_Requests(start_time) with fillfactor = 95
--create index IX_Log_Exec_Requests_reads on Log_Exec_Requests(start_time) with fillfactor = 95
GO


insert into master.dbo.Log_Exec_Requests
SELECT
	GETDATE()
,	r.session_id
,	e.host_name
,	e.program_name
,	e.login_name
,	r.[status]
,	r.command
,	r.start_time
,	r.total_elapsed_time/1000 'elapsed_time_secs'
,	r.cpu_time/1000 'cpu_time_secs'
,	r.reads
,	r.logical_reads
,	r.writes
,	DatabaseName = DB_Name(r.database_id)
,	t.[text]
,	r.blocking_session_id
,	r.transaction_id
,	(r.granted_query_memory * 8)/1024 'granted_query_mem_MB'
,	r.dop
,	r.wait_type
,	r.wait_resource
,	r.sql_handle
,	r.plan_handle
FROM sys.dm_exec_requests r
	LEFT JOIN sys.dm_exec_sessions e ON r.session_id = e.session_id
	CROSS APPLY	sys.dm_exec_sql_text(r.sql_handle) AS t

--select * from master.dbo.Log_Exec_Requests order by timestamp desc
