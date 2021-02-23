SELECT
	r.session_id 'spid'
,	r.blocking_session_id 'blocking_spid'
,	e.host_name
,	e.program_name
,	e.login_name
,	r.[status]
,	r.command
,	r.start_time
,	r.total_elapsed_time/1000 'elapsedtime_sec'
,	r.percent_complete '%'
,	r.cpu_time/1000 'cputime_sec'
,	r.reads
,	r.logical_reads
,	r.writes
,	DB_Name(r.database_id) 'DBName'
,	t.[text]
,	SUBSTRING(
				t.[text], r.statement_start_offset / 2, 
				(	CASE WHEN r.statement_end_offset = -1 THEN DATALENGTH (t.[text]) 
						 ELSE r.statement_end_offset 
					END - r.statement_start_offset ) / 2 
			 ) AS [executing statement] 
,	r.transaction_id 'tran_id'
,	(r.granted_query_memory * 8)/1024 'granted_query_mem_MB'
--,	r.dop
,	r.wait_type
,	r.wait_resource
,	r.sql_handle
,	r.plan_handle
,	OBJECT_NAME(t.objectid,t.dbid) 'objectname'
,	e.client_interface_name
,	p.query_plan,
*
FROM sys.dm_exec_requests r
	LEFT JOIN sys.dm_exec_sessions e ON r.session_id = e.session_id
	CROSS APPLY	sys.dm_exec_sql_text(r.sql_handle) AS t
	CROSS APPLY	sys.dm_exec_query_plan(r.plan_handle) AS p
ORDER BY r.total_elapsed_time DESC;
