USE master
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
----------------------------------------------------------------------------------------------------
-- OBJECT NAME			:	uspp_Backup_Restore_DB
--
-- AUTHOR				:	Riken Patel
--
-- INPUTS				:	@Backup_DBName - name of the database to be backed up
--							@Backup_Path - location of the backup 
--							@BackupOnly - specify if backup only (=1) or backup and restore (=0)
--							@Backup_DB_DataFile_LogicalName - logical name of the data file for the backed up database
--							@Backup_DB_LogFile_LogicalName - logical name of the log file for the backed up database
--							@Restore_DBName - name of the database to be restored
--							@Restore_DB_DataFilePath - location of the data file for the restored database
--							@Restore_DB_LogFilePath - location of the log file for the restored database
--
-- OUTPUTS				:	None
-- DEPENDENCIES			:	None
--
-- DESCRIPTION			:	full backup and restore
--
----------------------------------------------------------------------------------------------------

ALTER PROC uspp_Backup_Restore_DB
(
@Backup_DBName SYSNAME,
@Backup_Path VARCHAR(200),
@BackupOnly BIT,
@Backup_DB_DataFile_LogicalName VARCHAR(200) = null,
@Backup_DB_LogFile_LogicalName VARCHAR(200) = null,
@Restore_DBName SYSNAME = null,
@Restore_DB_DataFilePath VARCHAR(200) = null,
@Restore_DB_LogFilePath VARCHAR(200) = null
)

AS

SET NOCOUNT ON

DECLARE @Backup_Filename VARCHAR(200)
DECLARE @cmd SYSNAME
DECLARE @Result INT

--get current date and time
DECLARE @Now CHAR(14) = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(50), GETDATE(), 120), '-', ''), ' ', ''), ':', '')

SET @Backup_Filename = @Backup_Path + @Backup_DBName + '\' + @Backup_DBName + '_' + @Now + '.BAK'


EXEC master.dbo.sp_configure 'show advanced options', 1

RECONFIGURE

EXEC master.dbo.sp_configure 'xp_cmdshell', 1

RECONFIGURE

-- Build the dir command that will check to see if the directory exists
SET @cmd = 'dir ' + @Backup_Filename

-- Run the dir command, put output of xp_cmdshell into @result
EXEC @result = master.dbo.xp_cmdshell @cmd

-- If the directory does not exist, we must create it
IF @result <> 0
BEGIN

-- Build the mkdir command  
SELECT @cmd = 'mkdir ' + @Backup_Path + @Backup_DBName

-- Create the directory
EXEC master.dbo.xp_cmdshell @cmd, NO_OUTPUT

END
 

BACKUP DATABASE @Backup_DBName
TO DISK = @Backup_Filename



IF @BackupOnly = 0
BEGIN
--restore the backed up database

	SET @Restore_DB_DataFilePath = @Restore_DB_DataFilePath + @Restore_DBName + '.mdf'
	SET @Restore_DB_LogFilePath = @Restore_DB_LogFilePath + @Restore_DBName + '.ldf'
	
	RESTORE DATABASE @Restore_DBName
	FROM DISK = @Backup_Filename
	WITH RECOVERY, REPLACE,
	MOVE @Backup_DB_DataFile_LogicalName TO @Restore_DB_DataFilePath,
	MOVE @Backup_DB_LogFile_LogicalName TO @Restore_DB_LogFilePath
	
END


EXEC master.dbo.sp_configure 'xp_cmdshell', 0

RECONFIGURE

GO