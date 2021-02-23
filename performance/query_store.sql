select top 10 * from sys.query_store_query_text 
select top 10 * from sys.query_store_query 
select top 10 * from sys.query_store_plan
select top 100 * from sys.query_store_runtime_stats
select top 100 * from sys.query_store_wait_stats

declare @max_
select object_name(q.object_id),
	q.last_compile_start_time,
	q.last_execution_time,
	t.query_sql_text
,*
from sys.query_store_query q
	inner join sys.query_store_query_text t on q.query_text_id = t.query_text_id
	inner join sys.query_store_plan p on q.query_text_id = t.query_text_id
	inner join sys.query_store_runtime_stats s on s.plan_id = p.plan_id
where q.is_internal_query = 0
order by q.last_execution_time desc

