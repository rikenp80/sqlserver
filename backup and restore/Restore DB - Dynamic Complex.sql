USE [master]
GO

DECLARE @BackupFilePath NVARCHAR(500) = 'H:\Backup\.bak'
DECLARE @RestoreFileListSQL NVARCHAR(500) = 'RESTORE FILELISTONLY FROM DISK = ''' + @BackupFilePath + ''''

DECLARE @FileList TABLE
	(LogicalName nvarchar(128),
	PhysicalName nvarchar(260),
	Type char(1),
	FileGroupName nvarchar(128),
	Size numeric(20,0),
	MaxSize numeric(20,0),
	FileID bigint,
	CreateLSN numeric(25,0),
	DropLSN numeric(25,0) NULL,
	UniqueID uniqueidentifier,
	ReadOnlyLSN numeric(25,0) NULL,
	ReadWriteLSN numeric(25,0) NULL,
	BackupSizeInBytes bigint,
	SourceBlockSize int,
	FileGroupID int,
	LogGroupGUID uniqueidentifier NULL,
	DifferentialBaseLSN numeric(25,0) NULL,
	DifferentialBaseGUID uniqueidentifier,
	IsReadOnly bit,
	IsPresent bit,
	TDEThumbprint varbinary(32))

INSERT INTO @FileList EXEC sp_executesql @RestoreFileListSQL

SELECT	LogicalName,
		LEFT(PhysicalName, LEN(PhysicalName) - CHARINDEX('\', REVERSE(PhysicalName))) 'Old_Directory',
		Right(PhysicalName, CHARINDEX('\', REVERSE(PhysicalName))) 'PhysicalFileName',
		Type,
		FilegroupName
FROM @FileList


RESTORE DATABASE 
FROM DISK = @BackupFilePath
WITH RECOVERY, REPLACE, STATS = 1,
MOVE '' TO 'D:\sqldata\.mdf',
MOVE '' TO 'D:\sqldata\.ndf',
MOVE '' TO 'F:\sqllog\.ldf'
GO