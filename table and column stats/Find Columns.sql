SELECT	b.name 'table_name', a.name 'column_name', t.name 'data_type', a.length, a.collation
FROM sys.syscolumns a INNER JOIN sys.tables b ON a.id = b.[object_id]
	inner join sys.types t on a.xtype = t.user_type_id
WHERE a.name like ''
order by a.name, b.name