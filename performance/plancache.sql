select * from sys.dm_exec_cached_plans
select * from sys.dm_exec_sql_text 
select * from sys.dm_exec_query_statsselect * from sys.dm_exec_text_query_plan 

select * from sys.dm_exec_requests
select * from sys.dm_exec_xml_handles



SELECT
creation_time,
last_execution_time,
execution_count,
qs.total_worker_time/nullif(qs.execution_count,0) 'average_cpu_time',
(qs.total_worker_time/(nullif(qs.execution_count,0)))/1000000.0 'average_cpu_time_secs',
(qs.total_elapsed_time/(nullif(qs.execution_count,0)))/1000000.0 'average_elapsed_time_secs',
qs.total_logical_reads/nullif(qs.execution_count,0) 'average_logical_reads',
qs.total_logical_writes/nullif(qs.execution_count,0) 'average_logical_writes',
qs.last_physical_reads/nullif(qs.execution_count,0) 'average_physical_reads',
min_rows,
max_rows,
query_hash,
text,
sql_handle,
plan_handle,
*	
FROM sys.dm_exec_query_stats AS qs 
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt 
WHERE qt.text not like '%dm_exec_query_stats%'

order by qs.max_worker_time desc




select * from sys.dm_exec_cached_plans where plan_handle = 0x020000003B01590C7F1B95A6593F0AD3F87BFBC8EB8E99D10000000000000000000000000000000000000000
select * from sys.dm_exec_text_query_plan (0x020000003B01590C7F1B95A6593F0AD3F87BFBC8EB8E99D10000000000000000000000000000000000000000,0,-1)
select * from sys.dm_exec_query_plan  (0x020000003B01590C7F1B95A6593F0AD3F87BFBC8EB8E99D10000000000000000000000000000000000000000)
