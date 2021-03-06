USE [master]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
----------------------------------------------------------------------------------------------------
-- OBJECT NAME			:	uspp_RestoreDB_MapOrphanedUsers
--
-- AUTHOR				:	Riken Patel
--
-- INPUTS				:	@Restore_DBName - name of the database to be restored
--							@@Backup_FilePath - location of the backup 
--							@Backup_DB_DataFile_LogicalName - logical name of the data file for the backed up database
--							@Backup_DB_LogFile_LogicalName - logical name of the log file for the backed up database
--							@Restore_DB_DataFilePath - location of the data file for the restored database
--							@Restore_DB_LogFilePath - location of the log file for the restored database
--
-- OUTPUTS				:	None
-- DEPENDENCIES			:	None
--
-- DESCRIPTION			:	restore a database from a different server and fix orphaned users
--
-- EXAMPLES (optional)  :	EXEC master.dbo.uspp_RestoreDB_MapOrphanedUsers 'LoungeAccess_dev1', 'E:\MSSQL\Backups\LoungeAccess_Sanitized_From_Live\LoungeAccess_Sanitized_20111021114145.BAK', 'LoungeAccessFinal', 'LoungeAccessFinal_log', 'E:\MSSQL\Data\LoungeAccess_dev1.mdf', 'E:\MSSQL\Logs\LoungeAccess_dev1.ldf'
----------------------------------------------------------------------------------------------------
ALTER PROC [dbo].[uspp_RestoreDB_MapOrphanedUsers]
(
@Restore_DBName SYSNAME,
@Backup_FilePath VARCHAR(200),
@Backup_DB_DataFile_LogicalName VARCHAR(200) = null,
@Backup_DB_LogFile_LogicalName VARCHAR(200) = null,
@Restore_DB_DataFilePath VARCHAR(200) = null,
@Restore_DB_LogFilePath VARCHAR(200) = null
)

AS

SET NOCOUNT ON

/*---------------------------------------------------------------------------------------------------------------------
restore database
---------------------------------------------------------------------------------------------------------------------*/
RESTORE DATABASE @Restore_DBName
FROM DISK = @Backup_FilePath
WITH RECOVERY, REPLACE,
MOVE @Backup_DB_DataFile_LogicalName TO @Restore_DB_DataFilePath,
MOVE @Backup_DB_LogFile_LogicalName TO @Restore_DB_LogFilePath



/*---------------------------------------------------------------------------------------------------------------------
map orphaned users automatically to matching login names
---------------------------------------------------------------------------------------------------------------------*/
DECLARE @SQLString VARCHAR(1000)
DECLARE @CurrentUserName SYSNAME

CREATE TABLE #OrphanedUsers (UserName SYSNAME, UserSID VARBINARY(85))

/*insert orphaned users into a temp table*/
SET @SQLString = "INSERT INTO #OrphanedUsers EXEC " + @Restore_DBName + ".sys.sp_change_users_login 'Report'"
EXEC (@SQLString)


/*get first orphaned UserName from temp table*/
SELECT @CurrentUserName = MIN(UserName)FROM #OrphanedUsers


/*loop through #OrphanedUsers table remapping each orphaned user to a login if possible*/
WHILE @CurrentUserName IS NOT NULL
BEGIN
	SET @SQLString = @Restore_DBName + ".sys.sp_change_users_login 'Auto_Fix', '" + @CurrentUserName + "'"
	
	/*execute @SQLString in a TRY CATCH block which will allow the proc to continue mapping other users if the current user does not have a login*/
	BEGIN TRY
		EXEC (@SQLString)
	END TRY
	BEGIN CATCH
		PRINT '****------------------------------------------------------------ERROR MAPPING USER TO LOGIN------------------------------------------------------------****'
		PRINT 'Orphaned user: ' + @CurrentUserName
		PRINT 'ErrorNumber: ' + CAST(ERROR_NUMBER() AS VARCHAR(500))
			+ '; ErrorSeverity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(500))
			+ '; ErrorProcedure: ' + ERROR_PROCEDURE()
			+ '; ErrorMessage: ' + ERROR_MESSAGE()
		PRINT '****---------------------------------------------------------------------------------------------------------------------------------------------------****'			
	END CATCH
	

	/*get the next UserName from #OrphanedUsers*/
	DELETE FROM #OrphanedUsers WHERE UserName = @CurrentUserName
	SELECT @CurrentUserName = MIN(UserName)FROM #OrphanedUsers
	
END


GO

