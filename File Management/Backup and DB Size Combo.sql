SET QUOTED_IDENTIFIER OFF
GO

use master;

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


declare @DBSize table (DBName varchar(500), CurrentSizeGB decimal(9,2), SpaceUsedGB decimal(9,2))
insert into @DBSize
select DBName, SUM(CurrentSizeGB) 'CurrentSizeGB', SUM(SpaceUsedGB) 'SpaceUsedGB'
from @data
where DBName NOT IN ('master','model','msdb','tempdb')
group by rollup (DBName, type_desc)
having type_desc is null;


use msdb;

with 
	cte_max_backup_date (database_name, max_backup_start_date)
as
(
select	database_name,
		max(backup_start_date)
from backupset b
where type = 'D'
group by database_name
)


select	@@servername 'server_name',
        b.database_name,
		b.backup_size/1024/1024/1024 'backup_size_GB',
		b.compressed_backup_size/1024/1024/1024 'compressed_backup_size_GB',
		d.CurrentSizeGB 'DB_CurrentSize_GB',
		d.SpaceUsedGB  'DB_SpaceUsed_GB'
from @DBSize d
	inner join backupset b on b.database_name = d.DBName
	inner join cte_max_backup_date c on b.backup_start_date = c.max_backup_start_date and b.database_name = c.database_name
where type = 'D' and b.database_name NOT IN ('master','model','msdb','tempdb')
order by b.database_name 
