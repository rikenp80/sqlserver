SET QUOTED_IDENTIFIER OFF
GO

declare @db_id int = 1
declare @max_db_id int
declare @db_name varchar(200)
declare @drive_letter char(1) = 'D'
declare @query varchar(2000)

declare @data table
(
	DBName varchar(200),
	CurrentSizeGB decimal(9,2),
	FreeSpaceGB decimal(9,2),
	SpaceUsedGB decimal(9,2),
	type_desc varchar(50),
	name varchar(500),
	physical_name varchar(500),
	[filegroup] varchar(500),
	growth_mb decimal (18,2),
	shrink_script varchar(1000),
	shrink_script_truncate varchar(1000),
	grow_script  varchar(1000)
)

select @max_db_id = max(database_id) from sys.databases


WHILE @db_id <= @max_db_id
BEGIN
	SELECT @db_name = name FROM sys.databases WHERE database_id = @db_id AND state_desc = 'ONLINE' and has_dbaccess(name) = 1

	SET @query = 
	"
	USE [" + @db_name + "]

	SELECT	'" + @db_name + "',
			d.size/128.0/1024.0 AS CurrentSizeGB,  
			d.size/128.0/1024.0 - CAST(FILEPROPERTY(d.name, 'SpaceUsed') AS INT)/128.0/1024.0 AS FreeSpaceGB,
			CAST(FILEPROPERTY(d.name, 'SpaceUsed') AS INT)/128.0/1024.0 AS SpaceUsedGB,
			d.type_desc,
			d.name,
			d.physical_name,
			f.name 'filegroup'	
	FROM sys.database_files d LEFT JOIN sys.filegroups f ON d.data_space_id = f.data_space_id
	WHERE d.physical_name like '" + @drive_letter + "%'
	"
	--print @query
	
	INSERT INTO @data
	EXEC (@query)

	SET @db_id += 1
END


select distinct *, left(physical_name,1) from @data

