SELECT

	DB_NAME(database_id) DBName, 
	OBJECT_NAME(object_id) ProcName,
	last_execution_time,
	execution_count,

	CASE WHEN DATEDIFF(second, cached_time, GETDATE()) < 1 THEN 0 ELSE
	cast(execution_count as decimal) / cast(DATEDIFF(second, cached_time, GETDATE()) as decimal) END ExecPerSecond,


	(total_elapsed_time/execution_count)/1000000 'avg_elapsed_time_secs',
	last_elapsed_time/1000000 'last_elapsed_time_secs',


	(total_worker_time/execution_count)/1000000 'avg_worker_time_secs',
	last_worker_time/1000000 'last_worker_time_secs',

	(total_logical_reads/execution_count) 'avg_logical_reads',
	last_logical_reads,

	(total_logical_writes/execution_count) 'avg_logical_writes',
	last_logical_writes,

	(total_physical_reads/execution_count) 'avg_physical_reads',
	last_physical_reads

	[sql_handle],
	plan_handle

FROM sys.dm_exec_procedure_stats s 
ORDER BY last_elapsed_time desc