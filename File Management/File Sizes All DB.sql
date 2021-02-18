SET QUOTED_IDENTIFIER OFF
GO

declare @db_id int = 1
declare @max_db_id int
declare @db_name varchar(200)
declare @drive_letter char(1) = 'S'
declare @query varchar(2000)

declare @data table
(
	DBName varchar(200),
	CurrentSizeMB decimal(9,2),
	FreeSpaceMB decimal(9,2),
	SpaceUsedMB decimal(9,2),
	type_desc varchar(50),
	name varchar(500),
	physical_name varchar(500),
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
	USE " + @db_name + "

	SELECT	'" + @db_name + "',
			size/128.0 AS CurrentSizeMB,  
			size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS FreeSpaceMB,
			CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS SpaceUsedMB,
			type_desc,
			name,
			physical_name,
			growth/128 'growth_mb',
			'use [" + @db_name + "] dbcc shrinkfile ('''+name+''', 1)',
			'use [" + @db_name + "] dbcc shrinkfile ('''+name+''', TRUNCATEONLY)',	
			'ALTER DATABASE [" + @db_name + "] MODIFY FILE ( NAME = '''+ name +''', FILEGROWTH = 5GB, MAXSIZE = UNLIMITED)'		
	FROM sys.database_files
	WHERE physical_name like '" + @drive_letter + "%'
	"
	--print @query
	
	INSERT INTO @data
	EXEC (@query)

	SET @db_id += 1
END


select distinct cast((FreeSpaceMB/CurrentSizeMB)*100 as decimal(9,2)) '%Free', *
from @data
--where FreeSpaceMB > 200
order by [%Free] desc