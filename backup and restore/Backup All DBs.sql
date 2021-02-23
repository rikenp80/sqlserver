USE master
GO
SET QUOTED_IDENTIFIER OFF
GO
SET NOCOUNT ON


/*Generate an execution script for each database that needs to be backed up*/
DECLARE @LoopExecuteScripts TABLE (exec_command VARCHAR(1000))

INSERT INTO @LoopExecuteScripts
SELECT "BACKUP DATABASE [" + name + "] TO DISK = 'X:\MSSQL\Backup\" + name + "_20151105_084600.BAK' WITH COMPRESSION, STATS = 5"
FROM sys.databases
WHERE name <> 'tempdb'


/*Loop through each record in @LoopExecuteScripts table and execute the command*/
DECLARE @Current_Record VARCHAR(1000)

SELECT @Current_Record = MIN(exec_command) FROM @LoopExecuteScripts


WHILE @Current_Record IS NOT NULL
BEGIN
	
	PRINT @Current_Record
	EXEC (@Current_Record)

	--Delete processed record
	DELETE FROM @LoopExecuteScripts WHERE exec_command = @Current_Record

	--Get next record to be processed
	SELECT @Current_Record = MIN(exec_command) FROM @LoopExecuteScripts

END