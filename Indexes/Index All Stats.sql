--create table #index_size (index_id int, [object_id] int, avg_page_space_used_in_percent float, page_count bigint)

declare @tables table (tablename varchar(500))

declare @tablename varchar(50)


insert into @tables
values
('')


while exists (select * from @tables)
begin
	
	select top 1 @tablename = tablename from @tables

	insert into #index_size
	select index_id, [object_id], avg_page_space_used_in_percent, page_count from sys.dm_db_index_physical_stats (DB_ID(), OBJECT_ID(@tablename), NULL, NULL , 'SAMPLED') ps

	delete from @tables where tablename = @tablename
end

select distinct
	t.name 'table',
	i.name 'index',
	i.index_id,
	i.type_desc,
	i.fill_factor,
	cast(si.rowcnt/1000000.0 as decimal(9,2)) 'rowcnt_millions',
	cast((((avg_page_space_used_in_percent/100) * (page_count * 8))/1024/1024) as decimal(9,2)) 'index_data_used_size_GB',
	ps.avg_page_space_used_in_percent,
	--s.page_io_latch_wait_count,
	s.page_io_latch_wait_in_ms,
	s.page_io_latch_wait_in_ms/1000/60/60 'page_io_latch_wait_in_hours',
	s.page_io_latch_wait_in_ms/s.page_io_latch_wait_count 'ms_per_page_io_latch_wait'
	
from #index_size ps
	INNER JOIN sys.indexes i ON ps.object_id = i.object_id AND ps.index_id = i.index_id
	INNER JOIN sys.tables t ON t.object_id = ps.object_id
	INNER JOIN sysindexes si ON si.id = t.object_id AND ps.index_id = si.indid
	INNER JOIN sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) s on s.index_id = ps.index_id and s.object_id = ps.object_id
order by t.name, i.index_id