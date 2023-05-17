USE MASTER

DECLARE @DBName SYSNAME
SET @DBName = 'model'

DECLARE @ExecSQL varchar(50)
DECLARE @Current_SPID VARCHAR(6)
SELECT @Current_SPID = min(s.session_id) from sys.dm_exec_sessions s where s.login_name = 'svc-kafka-cdc' and s.[status] = 'sleeping' and s.last_request_end_time < '2023-03-31 06:30'

WHILE @Current_SPID is not null
BEGIN
	SET @ExecSQL = 'KILL ' + @Current_SPID
	print @ExecSQL
	EXEC (@ExecSQL)
	SELECT @Current_SPID = min(s.session_id) from sys.dm_exec_sessions s where s.login_name = 'svc-kafka-cdc' and s.[status] = 'sleeping' and s.last_request_end_time < '2023-03-31 06:30'
END
GO