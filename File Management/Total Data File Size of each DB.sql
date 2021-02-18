SET QUOTED_IDENTIFIER OFF
GO

declare @db_id int = 1
declare @max_db_id int
declare @db_name varchar(200)
declare @query varchar(2000)

declare @data table
(
	DBName varchar(200),
	CurrentSizeGB decimal(9,2),
	FreeSpaceGB decimal(9,2),
	SpaceUsedGB decimal(9,2),
	type_desc varchar(50)
)

select @max_db_id = max(database_id) from sys.databases


WHILE @db_id <= @max_db_id
BEGIN

	SELECT @db_name = name FROM sys.databases WHERE database_id = @db_id AND state_desc = 'ONLINE' and has_dbaccess(name) = 1

	SET @query = 
	"
	USE " + @db_name + "

	SELECT	'" + @db_name + "',
			(size/128.0)/1024.0 AS CurrentSizeGB,  
			(size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0)/1024.0 AS FreeSpaceGB,
			(CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0)/1024.0 AS SpaceUsedGB,
			type_desc
	FROM sys.database_files
	"
	
	INSERT INTO @data
	EXEC (@query)

	SELECT @db_id = min(database_id) from sys.databases where database_id > @db_id
END



select DBName, SUM(CurrentSizeGB) 'CurrentSizeGB', SUM(FreeSpaceGB) 'FreeSpaceGB', SUM(SpaceUsedGB) 'SpaceUsedGB', isnull(type_desc, 'TOTAL')
from @data
--where type_desc = 'ROWS'
group by rollup (DBName, type_desc)
--order by DBName, type_desc desc