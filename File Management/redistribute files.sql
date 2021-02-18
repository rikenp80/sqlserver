
--USE [master]
--GO
--ALTER DATABASE [TotalCV] MODIFY FILE ( NAME = N'TotalCV_Data1', FILEGROWTH = 0)
--ALTER DATABASE [TotalCV] MODIFY FILE ( NAME = N'TotalCV_Data2', FILEGROWTH = 0)
--ALTER DATABASE [TotalCV] MODIFY FILE ( NAME = N'TotalCV_Data3', FILEGROWTH = 0)
--ALTER DATABASE [TotalCV] MODIFY FILE ( NAME = N'TotalCV_Data4', FILEGROWTH = 0)
--GO



USE unifiedjobs
GO
SELECT f.name, d.*
FROM sys.database_files d inner join sys.filegroups f ON d.data_space_id = f.data_space_id
order by f.name



USE [master]
GO
ALTER DATABASE [unifiedjobs]
ADD FILE	(	
			NAME = 'ActiveCandidate1',
			FILENAME = 'Q:\MSSQL\MSSQL.MSSQLSERVER.Data\unifiedjobs\ActiveCandidate1.ndf',
			SIZE = 4GB,
			FILEGROWTH = 100MB
			)
TO FILEGROUP [FTFG_ActiveCandidate]
GO


USE unifiedjobs
GO
DBCC SHRINKFILE (ActiveCandidate, emptyfile)
GO
alter database unifiedjobs remove file ActiveCandidate


USE unifiedjobs
GO
SELECT f.name, d.*
FROM sys.database_files d inner join sys.filegroups f ON d.data_space_id = f.data_space_id
order by f.name