select *
from sys.dm_exec_session_wait_stats a left join sys.dm_exec_sessions b on a.session_id = b.session_id
order by a.session_id 