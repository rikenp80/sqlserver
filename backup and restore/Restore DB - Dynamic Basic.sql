SET QUOTED_IDENTIFIER OFF
SET NOCOUNT ON

DECLARE @DBName VARCHAR(500)
DECLARE @BackupFilePath VARCHAR(5000)

DECLARE @RestoreCommand VARCHAR(5000)

DECLARE @LogicalName NVARCHAR(128) 
DECLARE @PhysicalName NVARCHAR(260)

DECLARE @NewPhysicalDataPath NVARCHAR(500)
DECLARE @NewPhysicalLogPath NVARCHAR(500)


SET @DBName = ''
SET @BackupFilePath = '.BAK'

SET @NewPhysicalDataPath = 'X:\MSSQL\Data'
SET @NewPhysicalLogPath = 'Y:\MSSQL\Data'


CREATE TABLE #RestoreFileList
(
	LogicalName 			NVARCHAR(128) 
	,PhysicalName 			NVARCHAR(260) 
	,Type 					CHAR(1) 
	,FileGroupName 			NVARCHAR(128) 
	,Size 					NUMERIC(20,0) 
	,MaxSize 				NUMERIC(20,0),
	Fileid					BIGINT,
	CreateLSN 				NUMERIC(25,0),
	DropLSN 				NUMERIC(25,0),
	UniqueID 				UNIQUEIDENTIFIER,
	ReadOnlyLSN 			NUMERIC(25,0),
	ReadWriteLSN 			NUMERIC(25,0),
	BackupSizeInBytes 		BIGINT,
	SourceBlocSize 			INT,
	FileGroupId 			INT,
	LogGroupGUID 			UNIQUEIDENTIFIER,
	DifferentialBaseLSN 	NUMERIC(25,0),
	DifferentialBaseGUID	UNIQUEIDENTIFIER,
	IsReadOnly 				BIT,
	IsPresent 				BIT,
	TDEThumbprint 			VARBINARY(32)
)


INSERT #RestoreFileList EXEC ('RESTORE FILELISTONLY FROM DISK = ''' + @BackupFilePath + '''')


SET @RestoreCommand = "ALTER DATABASE " + @DBName + " SET SINGLE_USER WITH ROLLBACK IMMEDIATE" + CHAR(10)
SET @RestoreCommand = @RestoreCommand + "RESTORE DATABASE " + @DBName + " FROM DISK = '" + @BackupFilePath + "'" + CHAR(10) + " WITH RECOVERY, REPLACE, STATS = 10"


WHILE EXISTS (SELECT * FROM #RestoreFileList)
BEGIN
	SELECT TOP 1 @LogicalName = LogicalName, @PhysicalName = PhysicalName FROM #RestoreFileList

	SET @RestoreCommand = @RestoreCommand + CHAR(10) + ", MOVE '" + @LogicalName + "' TO '" + @PhysicalName + "'"

	DELETE FROM #RestoreFileList WHERE LogicalName = @LogicalName
END


PRINT @RestoreCommand
EXEC (@RestoreCommand)

GO

DROP TABLE #RestoreFileList
GO
