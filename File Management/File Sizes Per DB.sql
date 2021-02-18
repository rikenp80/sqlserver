SELECT	(d.size/128.0)/1024.0 AS CurrentSizeGB,  
		(d.size/128.0 - CAST(FILEPROPERTY(d.name, 'SpaceUsed') AS INT)/128.0)/1024.0 AS FreeSpaceGB,
		(CAST(FILEPROPERTY(d.name, 'SpaceUsed') AS INT)/128.0)/1024.0 AS SpaceUsedGB,
		d.type_desc,
		d.name 'file_name',
		f.name 'filegroup',
		d.physical_name,
		d.growth/128 'growth_mb',
		'DBCC SHRINKFILE (' + d.name + ', 1)',
		'DBCC SHRINKFILE (' + d.name + ', TRUNCATEONLY)'
FROM sys.database_files d LEFT JOIN sys.filegroups f ON d.data_space_id = f.data_space_id
ORDER BY f.name, d.name