SELECT 
	s.Name + '.' + t.NAME,
    s.Name AS SchemaName,
	t.NAME AS TableName,    
    p.rows AS RowCounts,
	a.data_space_id,
    (CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)))/1024.0 AS TotalSpaceGB,
    (CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)))/1024.0 AS UsedSpaceGB
FROM sys.tables t
		INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
		INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
		INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
		LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.NAME NOT LIKE 'dt%' 
    AND t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255	
GROUP BY t.Name, s.Name, p.Rows,a.data_space_id
ORDER BY UsedSpaceGB desc