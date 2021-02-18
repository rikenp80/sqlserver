
--USE [master]
--GO
--ALTER DATABASE [] MODIFY FILE ( NAME = N'', FILEGROWTH = 0)
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
			NAME = '',
			FILENAME = '',
			SIZE = 4GB,
			FILEGROWTH = 100MB
			)
TO FILEGROUP [FTFG_ActiveCandidate]
GO


USE unifiedjobs
GO
DBCC SHRINKFILE (, emptyfile)
GO
alter database []] remove file []]


USE unifiedjobs
GO
SELECT f.name, d.*
FROM sys.database_files d inner join sys.filegroups f ON d.data_space_id = f.data_space_id
order by f.name