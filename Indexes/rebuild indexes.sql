SELECT 	
	t.name AS TableName,
	si.name AS IndexName,
	si.rowmodctr,
	d.page_count,
	d.avg_fragmentation_in_percent,
	CASE WHEN t.lob_data_space_id = 0 THEN 'ALTER INDEX [' + si.name + '] ON [' + t.name+'] REBUILD WITH (ONLINE = ON)'
	ELSE 'ALTER INDEX [' + si.name + '] ON [' + t.name+'] REBUILD' END 'RebuildScript',
	*
FROM sys.dm_db_index_physical_stats (DB_ID('unifiedjobs'), NULL, NULL , NULL, 'LIMITED') d
	INNER JOIN sys.sysindexes si ON d.[object_id] = si.ID AND d.INDEX_ID = si.INDID
	INNER JOIN sys.tables t ON d.[object_id] = t.[object_id]	
WHERE si.NAME IS NOT NULL	
		AND d.page_count > 1000
		AND d.avg_fragmentation_in_percent > 25
ORDER BY d.page_count
