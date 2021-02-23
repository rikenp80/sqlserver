drop table #old
drop table #new
go

create table #old ([sql_handle] varbinary(max), average_physical_reads bigint, average_logical_reads bigint)
create table #new ([sql_handle] varbinary(max), average_physical_reads bigint, average_logical_reads bigint)
GO

insert into #new
select sql_handle, avg(average_physical_reads), avg(average_logical_reads)
from [QueryExecutionStats
where last_execution_time >= '2018-10-28'
group by sql_handle
having avg(average_physical_reads) > 0

insert into #old
select sql_handle, avg(average_physical_reads), avg(average_logical_reads)
from QueryExecutionStats
where last_execution_time between '2018-10-22' and '2018-10-28'
group by sql_handle
having avg(average_physical_reads) > 0


select o.*, n.average_physical_reads, n.average_logical_reads, o.average_physical_reads - n.average_physical_reads
from #old o inner join #new n on o.sql_handle = n.sql_handle
order by (o.average_physical_reads - n.average_physical_reads) desc


------------------------


use dbManagement
go
select
sql_handle,
sum(execution_count) 'execution_count',
sum(total_physical_reads) 'total_physical_reads',
sum(total_physical_reads)/sum(execution_count) 'avg_physical_reads',
SUM(average_cpu_time_secs) 'average_cpu_time_secs'
from QueryExecutionStats (nolock)
where cached_time > '2020-06-01'
group by sql_handle, query_text
order by sum(total_physical_reads) desc

use dbManagement
go
select TOP 20 *
from QueryExecutionStats (nolock)
where sql_handle = 0x020000005A53E91B3DF570AC4143FB23B5BB8C46644C19CF0000000000000000000000000000000000000000
order by cached_time desc

---------------------------

use dbManagement
go
select *
from QueryExecutionStats
where last_execution_time > '2018-10-10'
order by average_physical_reads desc
