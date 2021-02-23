SELECT DISTINCT	
		o.name,
		s.name,
		d.rows, 
		d.rows_sampled,
		d.unfiltered_rows,
		d.modification_counter,
		d.last_updated
		,*
FROM sys.stats s
	inner join sys.objects o on s.[object_id] = o.[object_id]
	CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) d
where o.type NOT IN ('S', 'IT')
order by d.[rows] desc