DECLARE @db_name VARCHAR(500)
DECLARE @proc_name VARCHAR(500) = ''



SELECT 	
	average_cpu_time*executions_per_min,
	average_cpu_time,
	average_cpu_time/1000000.0 'average_cpu_time_secs',
	executions_per_min,
	*
FROM SQLMaint.dbo.StoredProcExecutionStats (NOLOCK)
WHERE proc_name = @proc_name
ORDER BY cached_time desc



SELECT	o.name 'proc_name',
		CAST((ROUND(CAST(qs.execution_count AS DECIMAL(9,0))/nullif(CAST((DATEDIFF(ss,qs.cached_time,qs.last_execution_time)) AS DECIMAL(9,0)),0)*60,0)) as INT) 'exec/min',
		qs.total_worker_time/nullif(qs.execution_count,0) 'average_cpu_time',
		(qs.total_worker_time/(nullif(qs.execution_count,0)/1000000.0)) 'average_cpu_time_secs',
		qs.total_logical_reads/nullif(qs.execution_count,0) 'average_logical_reads',
		qs.total_logical_writes/nullif(qs.execution_count,0) 'average_logical_writes',
		qs.total_logical_writes/nullif(qs.execution_count,0) 'average_logical_writes',
		qs.last_physical_reads/nullif(qs.execution_count,0) 'average_physical_reads',
		qs.cached_time,
		qs.last_execution_time,
		qs.execution_count,
		st.[text],
		qp.query_plan,		
		qs.sql_handle,
		*		
from
    sys.dm_exec_procedure_stats as qs
	INNER JOIN unifiedjobs.sys.objects o ON qs.[object_id] = o.[object_id]
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as st
    CROSS APPLY sys.dm_exec_query_plan (qs.plan_handle) as qp
where o.name = @proc_name
order by average_cpu_time desc