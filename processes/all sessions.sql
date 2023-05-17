select s.host_name, s.program_name, db_name(r.database_id) 'db', user_name(r.user_id) 'user_name', s.login_name, r.wait_type, r.status, r.blocking_session_id, last_request_start_time, last_request_end_time, *
from sys.dm_exec_sessions s left join sys.dm_exec_requests r on  s.session_id = r.session_id
--where r.session_id = 195