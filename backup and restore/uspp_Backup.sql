USE [DBA_Logs]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
----------------------------------------------------------------------------------------------------
-- OBJECT NAME			:	uspp_Backup
--
-- AUTHOR				:	Riken Patel
--
-- INPUTS				:	@Backup_Path - directory in which the backup should be saved
--							@dbType - All, User or System
--							@Full_Frequency - the frequency in minutes of a Full Backup
--							@Diff_Frequency - the frequency in minutes of a Differential Backup
--							@Log_Frequency - the frequency in minutes of a Log Backup
--							@Scheduled - specifies if the backup was at a scheduled time, 1 = Yes, 0 = No
--
-- OUTPUTS				:	None
-- DEPENDENCIES			:	None
--
-- DESCRIPTION			:	Backup databases at specified intervals based on the values in the parameters	
--
-- EXAMPLES (optional)  :	exec uspp_Backup 'E:\MSSQL\Backups\', 'All', 1440, 480, 60
----------------------------------------------------------------------------------------------------

ALTER PROC [dbo].[uspp_Backup]
(
@Backup_Path VARCHAR(200),
@dbType VARCHAR(6),
@Full_Frequency INT,
@Diff_Frequency INT,
@Log_Frequency INT,
@Scheduled BIT = 0
)

AS


SET NOCOUNT ON

DECLARE @Backup_PathAndFilename VARCHAR(200)

DECLARE @PreviousBackupExists BIT
DECLARE @FullBackupScheduledTime BIT = 0

DECLARE @cmd SYSNAME
DECLARE @Result INT

DECLARE @Now CHAR(14)
DECLARE @BackupDateTime DATETIME2(0)

/*----------------------------------------------------------------------------------------------------------------------------------------------------
Few default variables for new databases.
-----------------------------------------------------------------------------------------------------------------------------------------------------*/


DECLARE @FirstFullBackupDate DATETIME2(0)

/* Full */
IF CAST(GETDATE() AS TIME) BETWEEN '00:30:00' AND '23:59:59'
BEGIN 
	--set to 00:30 on the current date
	SELECT @FirstFullBackupDate = DATEADD(MI, 30, CAST(CAST(GETDATE() AS DATE) AS DATETIME2(0)))
END
ELSE
BEGIN
	--set to 00:30 on the previous date
	SELECT @FirstFullBackupDate = DATEADD(MI, 30, CAST(CAST(GETDATE() - 1 AS DATE) AS DATETIME2(0)))
END


/*------------------------------------------------------------------------------------------------------------------------------------------------------
determine if backup compression is supported
------------------------------------------------------------------------------------------------------------------------------------------------------*/
DECLARE @ProductVersion DECIMAL(9,3)
DECLARE @Edition VARCHAR(200)
DECLARE @CompressionFlag BIT = 0


SELECT @ProductVersion = LEFT(CAST(SERVERPROPERTY('productversion') AS VARCHAR(200)), CHARINDEX('.',CAST(SERVERPROPERTY('productversion') AS VARCHAR(200)), 4)-1)
SELECT @Edition = CAST(SERVERPROPERTY('edition') AS VARCHAR(200))

IF (@Edition LIKE 'Enterprise Edition%' AND @ProductVersion >= 10) OR (@Edition LIKE 'Standard%' AND @ProductVersion >= 10.5) SET @CompressionFlag = 1


/*------------------------------------------------------------------------------------------------------------------------------------------------------
enable xp_cmdshell
------------------------------------------------------------------------------------------------------------------------------------------------------*/
EXEC master.dbo.sp_configure 'show advanced options', 1
RECONFIGURE

EXEC master.dbo.sp_configure 'xp_cmdshell', 1
RECONFIGURE


/*------------------------------------------------------------------------------------------------------------------------------------------------------
Get the list of the databases to be backed up
------------------------------------------------------------------------------------------------------------------------------------------------------*/
CREATE TABLE #WhichDatabase (dbName SYSNAME NOT NULL, dbType VARCHAR(10), recovery_model VARCHAR(60))

INSERT INTO #WhichDatabase (dbName, dbType, recovery_model)
SELECT RTRIM([name]),
		CASE WHEN [name] IN ('master', 'model', 'msdb') THEN 'System' ELSE 'User' END,
		recovery_model_desc
FROM sys.databases
WHERE [name] <> 'tempdb' AND state_desc = 'ONLINE'


/*If @dbType is System or USer then delete the other type from #WhichDatabase*/
IF @dbType = 'System'
BEGIN
	DELETE FROM #WhichDatabase WHERE dbType = 'User'
END	
ELSE
IF @dbType = 'User'
BEGIN
	DELETE FROM #WhichDatabase WHERE dbType = 'System'
END


/*------------------------------------------------------------------------------------------------------------------------------------------------------
Loop through each database in #WhichDatabase and backup
------------------------------------------------------------------------------------------------------------------------------------------------------*/
DECLARE @Current_dbName SYSNAME
DECLARE @Current_dbType VARCHAR(10)
DECLARE @Current_recovery_model VARCHAR(60)

DECLARE @Delete_Path VARCHAR(500)
DECLARE @Delete_dbName SYSNAME


SELECT @Current_dbName = MIN(dbName) FROM #WhichDatabase

SELECT	@Current_dbType = dbType,
		@Current_recovery_model = recovery_model
FROM #WhichDatabase
WHERE dbName = @Current_dbName


WHILE @Current_dbName IS NOT NULL
BEGIN

	/*--------------------------------------------------------------------------------------------------
	determine if a backup has taken place on the DB previously (for newly created DBs)
	so a Full backup is run instead of a Log or Diff
	
	if a the database is a System DB or the database is in Simple recovery model then
	log backups will not run therefore set @PreviousBackupExists = 1
	--------------------------------------------------------------------------------------------------*/
	IF @Current_dbType = 'System' OR @Current_recovery_model = 'SIMPLE'
	BEGIN
		SET @PreviousBackupExists = 1
	END
	ELSE
	BEGIN
		SELECT	@PreviousBackupExists = CASE WHEN last_log_backup_lsn IS NULL THEN NULL ELSE 1 END
		FROM	sys.database_recovery_status
		WHERE	database_id = DB_ID(@Current_dbName) 
	END	


	/*--------------------------------------------------------------------------------------------------
	Full Backup
	--------------------------------------------------------------------------------------------------*/
	SET @Now = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(50), GETDATE(), 120), '-', ''), ' ', ''), ':', '')
	SET @BackupDateTime = GETDATE()
	
	
	/*determine if this is the time that a scheduled full backup should occur
	check if a scheduled full backup has occured in the period specified by @Full_Frequency
	take 10 mins off the @Full_Frequency to allow for any delay in the time of previous backup*/
	IF @Scheduled = 1
		AND NOT EXISTS	(
						SELECT *
						FROM DBA_Logs.dbo.BackupLog
						WHERE DatabaseName = @Current_dbName
							AND BackupType = 'Full'
							AND Scheduled = 1
							AND BackupDateTime > DATEADD(MI, -(@Full_Frequency - 10), @BackupDateTime)
						)
	SET @FullBackupScheduledTime = 1
						


	IF	@Scheduled = 0 OR
		@PreviousBackupExists IS NULL OR
		@FullBackupScheduledTime = 1
												
	BEGIN
		print @Current_dbName
		print @Scheduled
		print @PreviousBackupExists
		print @FullBackupScheduledTime
		SET @Backup_PathAndFilename = @Backup_Path + @Current_dbName + '\' + @Current_dbName + '_Full_' + @Now + '.BAK'
		
		/*Build the dir command that will check to see if the directory exists*/
		SET @cmd = 'dir ' + @Backup_PathAndFilename

		/*Run the dir command, put output of xp_cmdshell into @result*/
		EXEC @result = master.dbo.xp_cmdshell @cmd

		/*If the directory does not exist, we must create it*/
		IF @result <> 0
		BEGIN
			/*Build the mkdir command*/
			SELECT @cmd = 'mkdir ' + @Backup_Path + @Current_dbName

			/*Create the directory*/
			EXEC master.dbo.xp_cmdshell @cmd, NO_OUTPUT
		END


		/*perform backup*/
		IF @CompressionFlag = 1
		BEGIN
			BACKUP DATABASE @Current_dbName
			TO DISK = @Backup_PathAndFilename
			WITH COMPRESSION
		END
		ELSE
		BEGIN
			BACKUP DATABASE @Current_dbName
			TO DISK = @Backup_PathAndFilename
		END
		
		
		/*if the backup was successful then log backup details in BackupLog table*/
		IF @@ERROR = 0
		BEGIN
			/*if the full backup is running at an unscheduled time when @Scheduled = 1 (this will be because @PreviousBackupExists = 0)*/
			/*then set Scheduled in BackupLog table to 0*/
			IF @FullBackupScheduledTime = 0
			BEGIN
				INSERT INTO DBA_Logs.dbo.BackupLog (DatabaseName, BackupType, BackupDateTime, BackupFileName, Scheduled)
				VALUES (@Current_dbName, 'Full', @BackupDateTime, @Backup_PathAndFilename, 0)
			END
			ELSE IF @PreviousBackupExists IS NULL
			BEGIN
				INSERT INTO DBA_Logs.dbo.BackupLog (DatabaseName, BackupType, BackupDateTime, BackupFileName, Scheduled)
				VALUES (@Current_dbName, 'Full', @FirstFullBackupDate, @Backup_PathAndFilename, 1)
			END
			ELSE
			BEGIN
				INSERT INTO DBA_Logs.dbo.BackupLog (DatabaseName, BackupType, BackupDateTime, BackupFileName, Scheduled)
				VALUES (@Current_dbName, 'Full', @BackupDateTime, @Backup_PathAndFilename, @Scheduled)						
			END
		END

		
		/*If a Full Backup has been performed then bypass the log and diff backups*/
		GOTO GET_NEXT_DB
		
	END


	/*--------------------------------------------------------------------------------------------------
	Differential Backup
	--------------------------------------------------------------------------------------------------*/
	/*if current database is a System DB then bypass the log and diff backups*/
	IF @Current_dbType = 'System' GOTO GET_NEXT_DB
	
	
	SET @Now = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(50), GETDATE(), 120), '-', ''), ' ', ''), ':', '')
	SET @BackupDateTime = GETDATE()


	/*check if a scheduled full or diff backup has occured in the period specified by @Diff_Frequency*/
	/*take 10 mins off the @Diff_Frequency to allow for any delay in the time of previous backup*/
	IF	@Scheduled = 0 OR
		(@Scheduled = 1
			AND NOT EXISTS	(SELECT *
							 FROM DBA_Logs.dbo.BackupLog
							 WHERE DatabaseName = @Current_dbName
								AND BackupType in ('Full', 'Diff')
								AND Scheduled = 1
								AND BackupDateTime > DATEADD(MI, -(@Diff_Frequency - 10), @BackupDateTime)
							)
		)
	BEGIN

		SET @Backup_PathAndFilename = @Backup_Path + @Current_dbName + '\' + @Current_dbName + '_Diff_' + @Now + '.BAK'
		
		-- Build the dir command that will check to see if the directory exists
		SET @cmd = 'dir ' + @Backup_PathAndFilename

		-- Run the dir command, put output of xp_cmdshell into @result
		EXEC @result = master.dbo.xp_cmdshell @cmd

		-- If the directory does not exist, we must create it
		IF @result <> 0
		BEGIN
			-- Build the mkdir command  
			SELECT @cmd = 'mkdir ' + @Backup_Path + @Current_dbName

			-- Create the directory
			EXEC master.dbo.xp_cmdshell @cmd, NO_OUTPUT
		END


		/*perform backup*/
		IF @CompressionFlag = 1
		BEGIN
			BACKUP DATABASE @Current_dbName
			TO DISK = @Backup_PathAndFilename
			WITH DIFFERENTIAL, COMPRESSION
		END
		ELSE
		BEGIN
			BACKUP DATABASE @Current_dbName
			TO DISK = @Backup_PathAndFilename
			WITH DIFFERENTIAL
		END
		

		/*if the backup was successful then log backup details in BackupLog table*/
		IF @@ERROR = 0
		BEGIN
			INSERT INTO DBA_Logs.dbo.BackupLog (DatabaseName, BackupType, BackupDateTime, BackupFileName, Scheduled)
			VALUES (@Current_dbName, 'Diff', @BackupDateTime, @Backup_PathAndFilename, @Scheduled)			
		END

		
	/*If a Diff Backup has been performed then bypass the log backup*/
	GOTO GET_NEXT_DB
		
	END


	/*--------------------------------------------------------------------------------------------------
	Log Backup
	--------------------------------------------------------------------------------------------------*/
	/*if current database uses simple recovery model then bypass the log backups*/
	IF @Current_recovery_model = 'SIMPLE' GOTO GET_NEXT_DB
	
	
	SET @Now = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(50), GETDATE(), 120), '-', ''), ' ', ''), ':', '')
	SET @BackupDateTime = GETDATE()


	/*check if a log backup has occured in the period specified by @Log_Frequency*/
	/*take 2 mins off the @Log_Frequency to allow for any delay in the time of previous backup*/
	IF	@Scheduled = 0 OR
		(@Scheduled = 1
			AND NOT EXISTS	(SELECT *
							 FROM DBA_Logs.dbo.BackupLog
							 WHERE DatabaseName = @Current_dbName
								AND BackupType IN ( 'Full', 'Diff', 'Log' )
								AND Scheduled = 1
								AND BackupDateTime > DATEADD(MI, -(@Log_Frequency - 2), @BackupDateTime)
							)
		)							
	BEGIN
		
		SET @Backup_PathAndFilename = @Backup_Path + @Current_dbName + '\' + @Current_dbName + '_Log_' + @Now + '.BAK'
		
		-- Build the dir command that will check to see if the directory exists
		SET @cmd = 'dir ' + @Backup_PathAndFilename

		-- Run the dir command, put output of xp_cmdshell into @result
		EXEC @result = master.dbo.xp_cmdshell @cmd

		-- If the directory does not exist, we must create it
		IF @result <> 0
		BEGIN
			-- Build the mkdir command  
			SELECT @cmd = 'mkdir ' + @Backup_Path + @Current_dbName

			-- Create the directory
			EXEC master.dbo.xp_cmdshell @cmd, NO_OUTPUT
		END


		/*perform backup*/
		IF @CompressionFlag = 1
		BEGIN
			BACKUP LOG @Current_dbName
			TO DISK = @Backup_PathAndFilename
			WITH COMPRESSION
		END
		ELSE
		BEGIN
			BACKUP LOG @Current_dbName
			TO DISK = @Backup_PathAndFilename
		END

				
		/*if the backup was successful then log backup details in BackupLog table*/
		IF @@ERROR = 0
		BEGIN
			INSERT INTO DBA_Logs.dbo.BackupLog (DatabaseName, BackupType, BackupDateTime, BackupFileName, Scheduled)
			VALUES (@Current_dbName, 'Log', @BackupDateTime, @Backup_PathAndFilename, @Scheduled)
		END
		
	END
	
	
	/*delete any old backup files and delete the current dbName from #WhichDatabase and get the next one to be backed up*/
	GET_NEXT_DB:
	
	SET @Delete_dbName = @Current_dbName + '*'
	SET @Delete_Path = @Backup_Path + @Current_dbName + '\'
	EXEC master.dbo.sp_Admin_Delete_Files_By_Date @Delete_Path, @Delete_dbName, 1
	
	
	DELETE FROM #WhichDatabase WHERE dbName = @Current_dbName
	
	SELECT @Current_dbName = MIN(dbName) FROM #WhichDatabase
	
	SELECT	@Current_dbType = dbType,
			@Current_recovery_model = recovery_model
	FROM #WhichDatabase
	WHERE dbName = @Current_dbName
	
END



EXEC master.dbo.sp_configure 'xp_cmdshell', 0
RECONFIGURE

EXEC master.dbo.sp_configure 'show advanced options', 0
RECONFIGURE

GO