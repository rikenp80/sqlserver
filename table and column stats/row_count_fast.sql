SELECT s.name + '.' + t.name 'schema + table', s.name 'schema', t.NAME 'table', i.rowcnt, cast(i.rowcnt/1000000.0 as decimal(9,2)) 'rowcnt_millions', max(i.indid) 'max_ind_id'
FROM sysindexes i INNER JOIN sys.tables t ON i.id = t.object_id
	INNER JOIN sys.schemas s on t.schema_id = s.schema_id
where i.rowcnt <> 0
--and t.name = ''
group by s.name, t.NAME, i.rowcnt
order by i.rowcnt desc

