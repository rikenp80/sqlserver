USE DBA_Logs
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
----------------------------------------------------------------------------------------------------
-- OBJECT NAME			:	uspp_Rebuild_Indexes
--
-- AUTHOR				:	Riken Patel
--
-- INPUTS				:	@DatabaseName - name of the database to have indexes rebuilt. If no value is specified then all databases will be affected.
--
-- OUTPUTS				:	None
-- DEPENDENCIES			:	None
--
-- DESCRIPTION			:	rebuild fragmented indexes on all databases on the server
----------------------------------------------------------------------------------------------------

ALTER PROCEDURE uspp_Rebuild_Indexes @DatabaseName VARCHAR(200) = NULL

AS

SET NOCOUNT ON


/*--------------------------------------------------------------------------------------------------
set @ProductVersion and @Edition and use them to determine if online rebuilds are possible
--------------------------------------------------------------------------------------------------*/
DECLARE @ProductVersion DECIMAL(9,3),
		@Edition VARCHAR(200),
		@Online	BIT

--get the first part of the productversion before the second decimal so that the value can be saved as a decimal
SELECT @ProductVersion = LEFT(CAST(SERVERPROPERTY('productversion') AS VARCHAR(200)), CHARINDEX('.',CAST(SERVERPROPERTY('productversion') AS VARCHAR(200)), 4)-1)
SELECT @Edition = CAST(SERVERPROPERTY('edition') AS VARCHAR(200))

IF	(@Edition LIKE 'Enterprise Edition%' AND @ProductVersion >= 9)
	OR
	((@Edition LIKE '%Developer%' OR @Edition LIKE '%Evaluation%') AND @ProductVersion >= 10)
BEGIN
	SET @Online = 1
END ELSE BEGIN
	SET @Online = 0
END



/*--------------------------------------------------------------------------------------------------
Create table if it does not already exist in DBA_Logs database
which will store a history of rebuilt and reorganized indexes
--------------------------------------------------------------------------------------------------*/
IF object_id('Log_Index_Rebuild') IS NULL
BEGIN
	CREATE TABLE Log_Index_Rebuild
	(
		Log_Index_Rebuild_ID	INT IDENTITY(1,1) NOT NULL,
		DatabaseName			VARCHAR(200) NOT NULL,
		TableName				VARCHAR(200) NOT NULL,
		IndexName				VARCHAR(200) NOT NULL,
		BeforeRebuildFragment	INT NOT NULL,
		AfterRebuildFragment	INT NULL,
		RebuildDurationSecs		INT NULL,
		RunDate					DATETIME2(0)
	)
	ALTER TABLE Log_Index_Rebuild ADD CONSTRAINT PK_Log_Index_Rebuild__Log_Index_Rebuild_ID PRIMARY KEY (Log_Index_Rebuild_ID) WITH FILLFACTOR = 100
	ALTER TABLE Log_Index_Rebuild ADD CONSTRAINT DF_Log_Index_Rebuild__RunDate DEFAULT GETDATE() FOR RunDate
	CREATE INDEX IDX_Log_Index_Rebuild_RunDate ON Log_Index_Rebuild(RunDate) WITH FILLFACTOR = 100
END



/*--------------------------------------------------------------------------------------------------
store all databases or the selected database in a variable table
--------------------------------------------------------------------------------------------------*/
DECLARE @Databases TABLE
		(
		DatabaseID		INT NOT NULL,
		DatabaseName	VARCHAR(500) NOT NULL,
		DatabaseType	VARCHAR(10) NOT NULL,
		RecoveryModel	VARCHAR(60) NOT NULL
		)
		
INSERT INTO @Databases
EXEC DBA_Logs.dbo.uspp_GetDatabases 0, NULL, @DatabaseName, 'model'



/*--------------------------------------------------------------------------------------------------
loop through each database and get indexes to rebuild
--------------------------------------------------------------------------------------------------*/
DECLARE @Current_DatabaseID			INT,
		@CurrentDatabaseName		VARCHAR(500),	
		@DBCollation				VARCHAR(500),		
		@SQL						VARCHAR(2000),
		@StartTime					TIME,
		@EndTime					TIME,
		@RebuildDurationSecs		INT

DECLARE @NoOnlineRebuild_Tables TABLE (TableName VARCHAR(500))



/*get initial DatabaseID value from @Databases and loop through each database in @Databases*/
SELECT @Current_DatabaseID = MIN(DatabaseID) FROM @Databases

WHILE @Current_DatabaseID IS NOT NULL
BEGIN

	/*save current database name and collation in a variable*/
	SELECT @CurrentDatabaseName = DatabaseName FROM @Databases WHERE DatabaseID = @Current_DatabaseID
	SELECT @DBCollation = CAST(DATABASEPROPERTYEX(@CurrentDatabaseName, 'Collation') AS VARCHAR(500))
	
	
	
	/*temporary table to store fragmented indexes - build with same collation as that of the database*/
	SET @SQL = "IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('DBA_Logs.dbo.RebuildIndexes') AND type in (N'U'))
				DROP TABLE DBA_Logs.dbo.RebuildIndexes
				CREATE TABLE DBA_Logs.dbo.RebuildIndexes
							(
							RebuildIndexID					INT IDENTITY(1,1),
							DatabaseName					VARCHAR(200) COLLATE " + @DBCollation + ",
							SchemaName						VARCHAR(200) COLLATE " + @DBCollation + ",
							TableName						VARCHAR(200) COLLATE " + @DBCollation + ",
							IndexName						VARCHAR(500) COLLATE " + @DBCollation + ",
							AvgPageFragmentation			INT,	
							AfterRebuild_AvgPageFragmentation INT,
							LastRunDate						DATETIME2(0),
							RebuildDurationSecs				INT
							)"
	EXECUTE(@SQL)
	
	
	
	/*Cannot do online rebuild if table containing index has a data type that does not allow it*/
	SET @SQL =
			"
			SELECT OBJECT_NAME(c.[object_id], " + CAST(@Current_DatabaseID AS VARCHAR(10)) + ")
			FROM [" + @CurrentDatabaseName + "].sys.columns c INNER JOIN [" + @CurrentDatabaseName + "].sys.types t ON c.user_type_id=t.user_type_id
			WHERE t.name IN ('text', 'ntext', 'image', 'xml') or (t.name IN ('varchar', 'nvarchar', 'varbinary') and c.max_length = -1)
			"

	DELETE FROM @NoOnlineRebuild_Tables
	INSERT INTO @NoOnlineRebuild_Tables (TableName)
	EXECUTE(@SQL)
	
	
	
	/*get all indexes in the current database where the index as had a insert, update or delete
	which is determined using sysindexes.rowmodctr column.
	also, get the previous run date and previous run duration and store it all in RebuildIndexes table.*/
	SET @SQL =	"
				SELECT a.DBName, a.SchemaName, a.TableName, a.IndexName, a.avg_fragmentation_in_percent, a.LastRunDate, b.RebuildDurationSecs
				FROM
					(
					SELECT '" + @CurrentDatabaseName + "' AS DBName,
						s.name AS SchemaName,
						t.name AS TableName,
						si.name AS IndexName,
						MAX(d.avg_fragmentation_in_percent) AS avg_fragmentation_in_percent,
						MAX(l.RunDate) 'LastRunDate'
					FROM [" + @CurrentDatabaseName + "].sys.dm_db_index_physical_stats (" + CAST(@Current_DatabaseID AS VARCHAR(10)) + ", NULL, NULL , NULL, 'LIMITED') d
						INNER JOIN [" + @CurrentDatabaseName + "].sys.sysindexes si ON d.[object_id] = si.ID AND d.INDEX_ID = si.INDID
						INNER JOIN [" + @CurrentDatabaseName + "].sys.tables t ON d.[object_id] = t.[object_id]
						INNER JOIN [" + @CurrentDatabaseName + "].sys.schemas s ON s.[schema_id] = t.[schema_id]
						LEFT JOIN DBA_Logs.dbo.Log_Index_Rebuild l ON si.name = l.IndexName AND t.name = l.TableName AND l.DatabaseName = '" + @CurrentDatabaseName + "' 
					WHERE si.NAME IS NOT NULL
							AND si.rowmodctr > 0
							AND d.page_count > 1000
							AND d.avg_fragmentation_in_percent > 5
					GROUP BY s.name, t.name, si.name
				) a
				LEFT JOIN Log_Index_Rebuild b
							ON a.DBName = b.DatabaseName
								AND a.TableName = b.TableName
								AND a.IndexName = b.IndexName
								AND a.LastRunDate = b.RunDate
				GROUP BY a.DBName, a.SchemaName, a.TableName, a.IndexName, a.avg_fragmentation_in_percent, a.LastRunDate, b.RebuildDurationSecs
				"

	INSERT INTO RebuildIndexes (DatabaseName, SchemaName, TableName, IndexName, AvgPageFragmentation, LastRunDate, RebuildDurationSecs) 
	EXECUTE(@SQL)

	
	/*--------------------------------------------------------------------------------------------------
	loop through each index in RebuildIndexes table and rebuild the index
	--------------------------------------------------------------------------------------------------*/
	DECLARE	@CurrentSchemaName			VARCHAR(200),
			@CurrentTableName			VARCHAR(200),
			@CurrentIndexName			VARCHAR(200),
			@CurrentLastRunDate			DATETIME2(0),
			@CurrentRebuildDurationSecs	INT,
			@CurrentRebuildIndexID		INT,
			@AvgPageFragmentation		INT

	SELECT @CurrentRebuildIndexID = MIN(RebuildIndexID) FROM RebuildIndexes
	
	WHILE @CurrentRebuildIndexID <= (SELECT MAX(RebuildIndexID) FROM RebuildIndexes)
	BEGIN

		/*save index details in variables*/
		SELECT	@CurrentSchemaName = SchemaName,
				@CurrentTableName = TableName,
				@CurrentIndexName = IndexName,
				@CurrentLastRunDate = LastRunDate,
				@CurrentRebuildDurationSecs = RebuildDurationSecs,
				@CurrentRebuildDurationSecs = RebuildDurationSecs,
				@AvgPageFragmentation = AvgPageFragmentation
		FROM RebuildIndexes
		WHERE RebuildIndexID = @CurrentRebuildIndexID
	


		/*exit current record process if the last rebuild took more than 5 minutes and it was run less than a week ago
		and bypass rebuilding process and go to next record*/
		IF (GETDATE() < DATEADD(wk, 1, CAST(@CurrentLastRunDate AS DATE))) AND @CurrentRebuildDurationSecs >= 300
		BEGIN
			DELETE FROM RebuildIndexes WHERE DatabaseName = @CurrentDatabaseName AND TableName = @CurrentTableName AND IndexName = @CurrentIndexName
			GOTO GET_NEXT_REBUILDINDEXID
		END
		
		
		
		/*create rebuild index script and check @NoOnlineRebuild_Tables table
		and @Online variable to determine if it can be rebuilt online*/
		IF @AvgPageFragmentation > 30
		BEGIN
			IF	NOT EXISTS (SELECT * FROM @NoOnlineRebuild_Tables WHERE TableName = @CurrentTableName)
				AND @Online = 1
			BEGIN
				SET @SQL = 'SET QUOTED_IDENTIFIER ON ALTER INDEX ' + @CurrentIndexName + ' ON [' + @CurrentDatabaseName + '].[' + @CurrentSchemaName + '].[' + @CurrentTableName+'] REBUILD WITH (ONLINE = ON)'
			END
			ELSE
			BEGIN
				SET @SQL = 'SET QUOTED_IDENTIFIER ON ALTER INDEX ' + @CurrentIndexName + ' ON [' + @CurrentDatabaseName + '].[' + @CurrentSchemaName + '].[' + @CurrentTableName+'] REBUILD'
			END
		END
		ELSE
		BEGIN
			SET @SQL = 'SET QUOTED_IDENTIFIER ON ALTER INDEX ' + @CurrentIndexName + ' ON [' + @CurrentDatabaseName + '].[' + @CurrentSchemaName + '].[' + @CurrentTableName+'] REORGANIZE'
		END
		
		
		/*Run the rebuild statement and get the duration of the execution*/
		SET @StartTime = GETDATE()
		print @SQL
		EXECUTE(@SQL)
		
		SET @EndTime = GETDATE()
		SET @RebuildDurationSecs = DATEDIFF(s, @StartTime, @EndTime)



		/*update RebuildIndexes with new fragmentation values and RebuildDuration*/
		SET @SQL =	"
					UPDATE F
					SET F.AfterRebuild_AvgPageFragmentation = DPS.avg_fragmentation_in_percent,
						F.RebuildDurationSecs = " + CAST(@RebuildDurationSecs AS VARCHAR(10)) +
					"FROM [" + @CurrentDatabaseName + "].sys.dm_db_index_physical_stats (" + CAST(@Current_DatabaseID AS VARCHAR(10)) + ", NULL, NULL , NULL, 'LIMITED') DPS
						INNER JOIN [" + @CurrentDatabaseName + "].sys.sysindexes SI ON DPS.[object_id] = SI.ID AND DPS.INDEX_ID = SI.INDID
						INNER JOIN RebuildIndexes F ON F.TableName = OBJECT_NAME(DPS.[object_id], " + CAST(@Current_DatabaseID AS VARCHAR(10)) + ") and F.IndexName = SI.name
					WHERE SI.name = '" + @CurrentIndexName + "'
						and DPS.alloc_unit_type_desc = 'IN_ROW_DATA'
					"
		EXECUTE(@SQL)



		/*go to the next index in RebuildIndexes table*/
		GET_NEXT_REBUILDINDEXID:
		SET @CurrentRebuildIndexID = @CurrentRebuildIndexID + 1
		
	END



	/*at the end of processing one database, save the affected indexes in a log table*/
	INSERT INTO Log_Index_Rebuild (DatabaseName, TableName, IndexName, BeforeRebuildFragment, AfterRebuildFragment, RebuildDurationSecs)
	SELECT DatabaseName, TableName, IndexName, AvgPageFragmentation, AfterRebuild_AvgPageFragmentation, RebuildDurationSecs
	FROM RebuildIndexes
	
	
	/*drop RebuildIndexes for the next database*/
	DROP TABLE RebuildIndexes
	
	
	/*get the next database to be processed from @Databases*/
	DELETE FROM @Databases WHERE DatabaseID = @Current_DatabaseID
	SELECT @Current_DatabaseID = MIN(DatabaseID) FROM @Databases
	
END

GO


EXEC uspp_Rebuild_Indexes