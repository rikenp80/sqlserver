USE master
GO
SET QUOTED_IDENTIFIER OFF
GO
SET NOCOUNT ON


/*Generate an execution script for each database that needs to be backed up*/
DECLARE @DBs_ToBackup TABLE (DBName VARCHAR(1000))
INSERT INTO @DBs_ToBackup
SELECT name
FROM sys.databases
WHERE database_id > 4 and state_desc = 'ONLINE'


/*Loop through each record in @LoopExecuteScripts table and execute the command*/
DECLARE @BackupExecScript VARCHAR(1000)
DECLARE @Current_DB VARCHAR(1000)
DECLARE @CurrentDateTime VARCHAR(100)

SELECT @Current_DB = MIN(DBName) FROM @DBs_ToBackup

WHILE @Current_DB IS NOT NULL
BEGIN	
	
	set @CurrentDateTime = CONVERT(VARCHAR(50), GETDATE(), 112) + '_' + REPLACE(CONVERT(VARCHAR(50), GETDATE(), 108), ':', '') 
	set @BackupExecScript  = "BACKUP DATABASE " + @Current_DB + " TO DISK = 'H:\MSSQL\Backups\" + @@SERVICENAME + "\" + @Current_DB + "_" + @CurrentDateTime + ".BAK' WITH COMPRESSION"
	
	PRINT @BackupExecScript
	EXEC (@BackupExecScript)

	--Delete processed record and get next DB
	DELETE FROM @DBs_ToBackup WHERE DBName = @Current_DB
	SELECT @Current_DB = MIN(DBName) FROM @DBs_ToBackup
		
END