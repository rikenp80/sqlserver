SELECT xp.[name], xo.*
FROM sys.dm_xe_objects xo, sys.dm_xe_packages xp
WHERE xp.[guid] = xo.[package_guid] 
	AND xo.[object_type] = 'event' 
	and xo.description like '%sql%'
ORDER BY xp.[name], xo.[name]


select *
from sys.dm_xe_object_columns
where [object_name] = 'rpc_completed'


SELECT xp.[name], xo.*
FROM sys.dm_xe_objects xo, sys.dm_xe_packages xp
WHERE xp.[guid] = xo.[package_guid]
  AND xo.[object_type] = 'action'
ORDER BY xp.[name], xo.[name];


SELECT xp.[name], xo.*
FROM sys.dm_xe_objects xo, sys.dm_xe_packages xp
WHERE xp.[guid] = xo.[package_guid]
  AND xo.[object_type] = 'target'
ORDER BY xp.[name], xo.[name];


select * from sys.dm_xe_objects
select * from sys.dm_xe_packages
select * from sys.dm_xe_objects where object_type = 'action' order by name