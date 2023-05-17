SELECT t.name, i.name, c.name, ic.index_column_id, ic.is_included_column, i.is_disabled, i.is_unique, i.fill_factor, i.is_hypothetical
FROM sys.columns c INNER JOIN sys.tables t ON c.[object_id] = t.[object_id]
		left join sys.index_columns ic on ic.column_id = c.column_id and ic.object_id = c.object_id
		left join sys.indexes i on i.index_id = ic.index_id and i.object_id = c.object_id
WHERE i.name is not null and t.name = 'TBL_TransactionLogs'
order by t.name, i.name, ic.index_column_id