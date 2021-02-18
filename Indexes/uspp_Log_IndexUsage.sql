USE [DBA_Logs]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
----------------------------------------------------------------------------------------------------
-- OBJECT NAME			:	uspp_Log_IndexUsage
--
-- AUTHOR				:	Riken Patel
--
-- INPUTS				:	None
-- OUTPUTS				:	None
-- DEPENDENCIES			:	None
--
-- DESCRIPTION			:	Get index usage stats and log them in IndexUsageStats
----------------------------------------------------------------------------------------------------

ALTER PROC [dbo].[uspp_Log_IndexUsage]

AS

SET NOCOUNT ON


/*--------------------------------------------------------------------------------------------------
Get the list of the databases to get index stats from
--------------------------------------------------------------------------------------------------*/
CREATE TABLE #WhichDatabase (dbName SYSNAME NOT NULL, [dbid] INT NOT NULL)
INSERT INTO	#WhichDatabase
SELECT [name], database_id
FROM sys.databases
WHERE [name] NOT IN ('master', 'tempdb', 'model', 'msdb') AND state_desc = 'ONLINE'


/*--------------------------------------------------------------------------------------------------
Loop through each database in #WhichDatabase and insert index usage data into IndexUsageStats
--------------------------------------------------------------------------------------------------*/
CREATE TABLE #IndexUsageStats
	(
	DatabaseName		SYSNAME NOT NULL,
	SchemaName			SYSNAME NOT NULL,
	TableName			SYSNAME NOT NULL,
	IndexName			SYSNAME NOT NULL,
	IndexType			VARCHAR(60) NOT NULL,
	User_Seeks			BIGINT NULL,
	User_Scans			BIGINT NULL,
	User_Lookups		BIGINT NULL,
	User_Updates		BIGINT NULL,
	Last_User_Seek		DATETIME2(3) NULL,
	Last_User_Scan		DATETIME2(3) NULL,
	Last_User_Lookup	DATETIME2(3) NULL,
	Last_User_Update	DATETIME2(3) NULL,
	System_Seeks		BIGINT NULL,
	System_Scans		BIGINT NULL,
	System_Lookups		BIGINT NULL,
	System_Updates		BIGINT NULL,
	Last_System_Seek	DATETIME2(3) NULL,
	Last_System_Scan	DATETIME2(3) NULL,
	Last_System_Lookup	DATETIME2(3) NULL,
	Last_System_Update	DATETIME2(3) NULL
	)


DECLARE @SQL VARCHAR(5000)
DECLARE @Current_dbName SYSNAME
DECLARE @Current_dbid VARCHAR(10)

SELECT @Current_dbName = MIN(dbName) FROM #WhichDatabase
SELECT @Current_dbid = [dbid] FROM #WhichDatabase WHERE dbName = @Current_dbName


WHILE @Current_dbName IS NOT NULL
BEGIN

	SET @SQL =	"
				INSERT INTO #IndexUsageStats(DatabaseName, SchemaName, TableName, IndexName, IndexType, User_Seeks, User_Scans, User_Lookups, User_Updates, Last_User_Seek, Last_User_Scan, Last_User_Lookup, Last_User_Update, System_Seeks, System_Scans, System_Lookups, System_Updates, Last_System_Seek, Last_System_Scan, Last_System_Lookup, Last_System_Update)
				SELECT	d.name,
						s.name,
						t.name,
						i.name,
						i.type_desc,
						iu.user_seeks,
						iu.user_scans,
						iu.user_lookups,
						iu.user_updates,
						iu.last_user_seek,
						iu.last_user_scan,
						iu.last_user_lookup,
						iu.last_user_update,
						iu.system_seeks,
						iu.system_scans,
						iu.system_lookups,
						iu.system_updates,
						iu.last_system_seek,
						iu.last_system_scan,
						iu.last_system_lookup,
						iu.last_system_update
				FROM " + @Current_dbName + ".sys.dm_db_index_usage_stats iu
				INNER JOIN " + @Current_dbName + ".sys.indexes i ON iu.index_id = i.index_id and iu.object_id = i.object_id
				INNER JOIN " + @Current_dbName + ".sys.tables t ON i.object_id = t.object_id
				INNER JOIN " + @Current_dbName + ".sys.schemas s ON s.schema_id = t.schema_id
				INNER JOIN sys.databases d ON d.database_id = iu. database_id AND d.database_id = " + @Current_dbid + "
				WHERE i.type <> 0
				"

	EXEC(@SQL)
	
	/*go to next DB*/
	DELETE FROM #WhichDatabase WHERE dbName = @Current_dbName
	
	SELECT @Current_dbName = MIN(dbName) FROM #WhichDatabase
	SELECT @Current_dbid = [dbid] FROM #WhichDatabase WHERE dbName = @Current_dbName

END



/*insert new records into IndexUsageStats*/
INSERT INTO IndexUsageStats(DatabaseName, SchemaName, TableName, IndexName, IndexType, User_Seeks, User_Scans, User_Lookups, User_Updates, Last_User_Seek, Last_User_Scan, Last_User_Lookup, Last_User_Update, System_Seeks, System_Scans, System_Lookups, System_Updates, Last_System_Seek, Last_System_Scan, Last_System_Lookup, Last_System_Update)
SELECT DatabaseName, SchemaName, TableName, IndexName, IndexType, User_Seeks, User_Scans, User_Lookups, User_Updates, Last_User_Seek, Last_User_Scan, Last_User_Lookup, Last_User_Update, System_Seeks, System_Scans, System_Lookups, System_Updates, Last_System_Seek, Last_System_Scan, Last_System_Lookup, Last_System_Update
FROM #IndexUsageStats A
WHERE NOT EXISTS (SELECT * FROM IndexUsageStats B WHERE A.DatabaseName = B.DatabaseName AND A.SchemaName = B.SchemaName AND A.TableName = B.TableName AND A.IndexName = B.IndexName)



/*update existing records in IndexUsageStats with the latest stats*/
UPDATE A
SET A.IndexType = B.IndexType,
	A.User_Seeks = B.User_Seeks,
	A.User_Scans = B.User_Scans,
	A.User_Lookups = B.User_Lookups,
	A.User_Updates = B.User_Updates,
	
	A.Last_User_Seek = B.Last_User_Seek,
	A.Last_User_Scan = B.Last_User_Scan, 
	A.Last_User_Lookup = B.Last_User_Lookup, 
	A.Last_User_Update = B.Last_User_Update,
	
	A.System_Seeks = B.System_Seeks,
	A.System_Scans = B.System_Scans, 
	A.System_Lookups = B.System_Lookups, 
	A.System_Updates = B.System_Updates,
	
	A.Last_System_Seek = B.Last_System_Seek,
	A.Last_System_Scan = B.Last_System_Scan, 
	A.Last_System_Lookup = B.Last_System_Lookup, 
	A.Last_System_Update = B.Last_System_Update
		
FROM IndexUsageStats A INNER JOIN #IndexUsageStats B ON A.DatabaseName = B.DatabaseName AND A.SchemaName = B.SchemaName AND A.TableName = B.TableName AND A.IndexName = B.IndexName


GO
