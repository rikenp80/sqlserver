select	patindex('%File name=%',target_data),
		patindex('%events%',target_data),
		target_data,
		substring(target_data, patindex('%File name=%',target_data)+11, patindex('%events%',target_data)-patindex('%File name=%',target_data)+11)
from sys.dm_xe_sessions a
	inner join sys.dm_xe_session_targets b on a.address = b.event_session_address
where name = 'blocked_process'
GO
