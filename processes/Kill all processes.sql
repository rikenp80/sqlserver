USE MASTER

DECLARE @DBName SYSNAME
SET @DBName = 'model'

DECLARE @ExecSQL varchar(50)
DECLARE @Current_SPID VARCHAR(6)
SELECT @Current_SPID = MIN(spid) FROM sys.sysprocesses WITH(NOLOCK) WHERE dbid = DB_ID(@DBName)

WHILE @Current_SPID is not null
BEGIN
	SET @ExecSQL = 'KILL ' + @Current_SPID
	print @ExecSQL
	EXEC (@ExecSQL)
	SELECT @Current_SPID = MIN(spid) FROM sys.sysprocesses WITH(NOLOCK) WHERE dbid = DB_ID(@DBName)
END
GO