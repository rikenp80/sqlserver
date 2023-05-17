SET QUOTED_IDENTIFIER OFF
SET NOCOUNT ON
GO

DECLARE @username VARCHAR(500) = 'rate'

select * from sys.server_principals
WHERE name LIKE '%' + @username + '%'
ORDER by name


declare @db_id int = 5
declare @max_db_id int
declare @db_name varchar(200)
declare @query varchar(2000)
declare @data table (DBName sysname null, rolename sysname null, owning_principal_id int, user_name sysname null)

select @max_db_id = max(database_id) from sys.databases


WHILE @db_id <= @max_db_id
BEGIN
	SELECT @db_name = name FROM sys.databases WHERE database_id = @db_id AND state_desc = 'ONLINE' and has_dbaccess(name) = 1
	PRINT @db_name
	SET @query = 
	"
	USE [" + @db_name + "]

	SELECT	'" + @db_name + "',
		roles.name 'rolename', roles.owning_principal_id, users.name 'username'
	FROM sys.database_principals AS users 
		LEFT JOIN sys.database_role_members rm ON rm.member_principal_id = users.principal_id
		LEFT JOIN sys.database_principals roles ON rm.role_principal_id = roles.principal_id
	WHERE users.name like '%" + @username + "%'"
	
	PRINT @query
	INSERT INTO @data
	EXEC (@query)

	SET @db_id += 1
END

SELECT * FROM @data ORDER BY DBName, rolename