select top 10 * from sys.query_store_query_text 
select top 10 * from sys.query_store_query 
select top 10 * from sys.query_store_plan where plan_id = 178
--select top 100 * from sys.query_store_wait_stats



select s.runtime_stats_interval_id, *
from sys.query_store_runtime_stats s
	inner join sys.query_store_plan p on s.plan_id = p.plan_id
	inner join sys.query_store_query q on p.query_id = q.query_id
	inner join sys.query_store_query_text qt on qt.query_text_id = q.query_text_id
where s.runtime_stats_id = 47227



select top 100 * from 	sys.query_store_runtime_stats_interval order by end_time desc


set quoted_identifier off
go
select	
		cast(s.avg_duration/1000000 as decimal(19,6)) 'avg_duration_secs',
		cast(s.avg_cpu_time/1000000 as decimal(19,6)) 'avg_cpu_time_secs',
		cast(s.last_duration/1000000 as int) 'last_duration_secs',
		s.first_execution_time,
		s.last_execution_time,
		dateadd(s, cast(s.last_duration/1000000 as int), s.last_execution_time) 'last_execution_end_time',
		cast(s.avg_cpu_time/1000000 as decimal(19,6)) * s.count_executions 'total_cpu_time_secs',
		cast(s.avg_duration/1000000 as decimal(19,6)) * s.count_executions 'total_duration_secs',
		s.count_executions,

		case when (datediff(ss, s.last_execution_time, s.first_execution_time)) = 0 then s.count_executions else cast(s.count_executions as decimal(9,2))/(datediff(ss, s.first_execution_time, s.last_execution_time)) end,
		*
from sys.query_store_runtime_stats s
	inner join sys.query_store_plan p on s.plan_id = p.plan_id
	inner join sys.query_store_query q on p.query_id = q.query_id
	inner join sys.query_store_query_text qt on qt.query_text_id = q.query_text_id
	inner join sys.dm_exec_query_stats qs on qt.statement_sql_handle = qs.statement_sql_handle
	--CROSS APPLY sys.dm_exec_query_plan (qs.plan_handle) as qp
where --s.runtime_stats_interval_id > 1180
--		and (cast(s.avg_cpu_time/1000000 as decimal(19,6)) * s.count_executions) > 1
 --query_sql_text like "%%"
 --statement_sql_handle = 0x0900EAB1A8E3E0C7B5872EFE601846BC497C0000000000000000000000000000000000000000000000000000
--q.query_text_id=16765
 q.query_text_id = 16764
 order by last_execution_end_time desc


--ALTER DATABASE [] SET QUERY_STORE (INTERVAL_LENGTH_MINUTES = 60)