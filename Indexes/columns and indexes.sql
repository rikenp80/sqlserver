SELECT c.name, t.name, i.name
FROM sys.columns c INNER JOIN sys.tables t ON c.[object_id] = t.[object_id]
		left join sys.index_columns ic on ic.column_id = c.column_id and ic.object_id = c.object_id
		left join sys.indexes i on i.index_id = ic.index_id and i.object_id = c.object_id
WHERE c.name = 'row_ts'
order by c.name, t.name, i.name