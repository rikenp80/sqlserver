select open_transaction_count, last_request_start_time, last_request_end_time, status, *
from sys.dm_exec_sessions e
where session_id > 50 and open_transaction_count > 0
order by e.last_request_start_time 


select open_transaction_count, last_request_start_time, last_request_end_time, status, *
from sys.dm_exec_sessions e
where session_id > 50 and open_transaction_count > 0 and status = 'sleeping' and e.last_request_end_time < DATEADD(second, -30, getdate())
order by e.last_request_start_time 


select DB_NAME(dbid), *
from sys.sysprocesses e
where e.spid > 50 and e.open_tran > 0
order by e.last_batch 

