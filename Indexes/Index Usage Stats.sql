declare @table varchar(60) = ''

select
	t.name 'table',
	i.name 'index',
	d.name 'filegroup',
	i.type_desc,
	i.fill_factor,
	cast(si.rowcnt/1000000.0 as decimal(9,2)) 'rowcnt_millions',
	--((si.used) * 8)/1024 AS IndexSizeMB,
	((si.used) * 8)/1024/1024 AS IndexSizeGB,
	s.range_scan_count,
	s.singleton_lookup_count,
	s.leaf_insert_count,
	s.leaf_delete_count,
	s.leaf_update_count,
	s.nonleaf_insert_count,
	s.nonleaf_delete_count,
	s.nonleaf_update_count,
	s.page_io_latch_wait_count,
	--s.page_io_latch_wait_in_ms,
	s.page_io_latch_wait_in_ms/1000/60 'page_io_latch_wait_in_hours',
	s.page_io_latch_wait_in_ms/s.page_io_latch_wait_count 'ms_per_page_io_latch_wait',
	s.row_lock_wait_in_ms,
	s.page_lock_wait_in_ms,
	s.page_latch_wait_in_ms,
	s.leaf_allocation_count,
	s.nonleaf_allocation_count,
	si.*	
FROM sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) s
	INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
	INNER JOIN sys.tables t ON t.object_id = s.object_id
	INNER JOIN sys.schemas sc ON sc.schema_id = t.schema_id
	INNER JOIN sysindexes si ON si.id = t.object_id AND s.index_id = si.indid
	INNER JOIN sys.data_spaces d on d.data_space_id = i.data_space_id
	INNER JOIN sys.dm_db_partition_stats AS p on p.[object_id] = i.[object_id] AND p.[index_id] = i.[index_id]
WHERE t.is_ms_shipped = 0
and s.page_io_latch_wait_count > 100
--and t.name = ''
order by s.page_io_latch_wait_in_ms desc








select sc.name, t.name, i.name, i.type_desc,
	s.user_lookups,
	s.user_scans,
	s.user_seeks,
	s.*
FROM sys.dm_db_index_usage_stats s
	INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
	INNER JOIN sys.tables t ON t.object_id = s.object_id
	INNER JOIN sys.schemas sc ON sc.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0
	and s.database_id = DB_ID()
	--and user_lookups+user_scans+user_seeks = 0
--		and t.name = @table
order by s.user_seeks desc
