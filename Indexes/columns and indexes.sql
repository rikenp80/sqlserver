SELECT c.name, t.name, i.name
FROM sys.columns c INNER JOIN sys.tables t ON c.[object_id] = t.[object_id]
		left join sys.index_columns ic on ic.column_id = c.column_id and ic.object_id = c.object_id
		left join sys.indexes i on i.index_id = ic.index_id and i.object_id = c.object_id
WHERE c.name = 'row_ts'
order by c.name, t.name, i.name


select 
o.name,
*
from sys.indexes i inner join sys.objects o on i.object_id = o.object_id
where i.type = 2
and o.type not in ('S', 'IT')
AND o.name not like 'sys%'
--and i.is_primary_key = 0
--and i.data_space_id = 1
order by o.name