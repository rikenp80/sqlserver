SELECT
creation_time,
last_execution_time,
execution_count,
CASE WHEN DATEDIFF(second, creation_time, GETDATE()) = 0 THEN cast(execution_count as decimal) ELSE
cast(cast(execution_count as decimal) / cast(DATEDIFF(second, creation_time, GETDATE()) as decimal) as decimal(18,4)) END ExecPerSecond,

CASE WHEN DATEDIFF(hour, creation_time, GETDATE()) = 0 THEN cast(execution_count as decimal) ELSE
cast(cast(execution_count as decimal) / cast(DATEDIFF(hour, creation_time, GETDATE()) as decimal) as decimal(18,4)) END ExecPerHour,

(CASE WHEN DATEDIFF(second, creation_time, GETDATE()) = 0 THEN 0 ELSE
cast(execution_count as decimal) / cast(DATEDIFF(second, creation_time, GETDATE()) as decimal) END) * ((qs.total_worker_time/(nullif(qs.execution_count,0)))/1000000.0) cpu_time_per_second,
qs.total_worker_time,
qs.total_worker_time/nullif(qs.execution_count,0) 'avg_cpu_time',
(qs.total_worker_time/(nullif(qs.execution_count,0)))/1000000.0 'avg_cpu_time_secs',
(qs.total_elapsed_time/(nullif(qs.execution_count,0)))/1000000.0 'avg_elapsed_time_secs',
qs.total_logical_reads/nullif(qs.execution_count,0) 'avg_logical_reads',
qs.total_logical_writes/nullif(qs.execution_count,0) 'avg_logical_writes',
qs.total_physical_reads,
qs.total_physical_reads/nullif(qs.execution_count,0) 'avg_physical_reads',
db_name(qp.dbid) 'DB',
text,
qp.query_plan,
*	
FROM sys.dm_exec_query_stats AS qs 
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt 
CROSS APPLY sys.dm_exec_query_plan (qs.plan_handle) as qp
WHERE qt.text not like '%dm_exec_query_stats%'
	--and db_name(qp.dbid) IN (APM02_DW')
	--and qt.text like '%SURVEYS_STAGE2_FACT%'

order by avg_physical_reads desc







