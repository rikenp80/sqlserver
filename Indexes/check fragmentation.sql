select *
FROM sys.dm_db_index_physical_stats(DB_ID(), null, null , NULL, 'limited') DPS
		INNER JOIN sys.sysindexes SI ON DPS.[object_id] = SI.ID AND DPS.INDEX_ID = SI.INDID
--WHERE DPS.alloc_unit_type_desc = 'IN_ROW_DATA'
order by avg_fragmentation_in_percent desc