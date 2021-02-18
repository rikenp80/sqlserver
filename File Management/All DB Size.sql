SET QUOTED_IDENTIFIER OFF
GO

declare @db_id int = 1
declare @max_db_id int
declare @db_name varchar(200)
declare @query varchar(2000)

declare @data table
(
	DBName varchar(200),
	CurrentSizeMB decimal(9,2),
	FreeSpaceMB decimal(9,2),
	SpaceUsedMB decimal(9,2),
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
			size/128.0 AS CurrentSizeMB,  
			size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS FreeSpaceMB,
			CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS SpaceUsedMB,
			type_desc
	FROM sys.database_files
	"
	
	INSERT INTO @data
	EXEC (@query)

	SET @db_id += 1
END


select DBName, SUM(CurrentSizeMB) 'CurrentSizeMB', SUM(FreeSpaceMB) 'FreeSpaceMB', SUM(SpaceUsedMB) 'SpaceUsedMB', (SUM(SpaceUsedMB))/1024 'SpaceUsedGB', type_desc
from @data
where type_desc = 'ROWS'
group by DBName, type_desc
order by SpaceUsedMB desc