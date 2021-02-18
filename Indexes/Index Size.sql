SELECT i.[name] 'IndexName',
	d.name 'filegroup'
	,p.object_id
	,i.index_id
	,OBJECT_NAME(p.object_id) 'TableName'
    ,(SUM(p.[used_page_count]) * 8)/1024/1024 AS IndexSizeGB
FROM sys.dm_db_partition_stats AS p
	INNER JOIN sys.indexes AS i ON p.[object_id] = i.[object_id] AND p.[index_id] = i.[index_id]
	inner join sys.objects s on p.[object_id] = s.[object_id]
	INNER JOIN sys.data_spaces d on d.data_space_id = i.data_space_id
WHERE i.type <> 0 and s.type <> 'S'
GROUP BY i.[name], OBJECT_NAME(p.object_id), i.index_id, p.object_id, d.name
ORDER BY IndexSizeGB desc