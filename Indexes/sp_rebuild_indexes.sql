/*Drop the procedure if it already exists*/
IF OBJECT_ID('[dbo].[sp_rebuild_Indexes]') IS NOT NULL
BEGIN
	DROP PROCEDURE sp_rebuild_Indexes
END
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

/*Create new version of the proc*/
CREATE PROCEDURE sp_rebuild_Indexes
AS
BEGIN
	DECLARE 
	@indexName		VARCHAR(100) 	/*Index to rebuild*/,
	@TableName		VARCHAR(100)	/*Table the index belongs to*/,
	@Fragmentation	INTEGER 		/*% fragmentaion*/,
	@OnlineOption	VARCHAR(50) 	/*If table contains text data type cannot rebuild online therefore remove */,
	@SQLStatement	VARCHAR(1000) 	/*The sql statement to run after being built*/,
	@LogID			INT				/*The log id*/
	
	/*Going to log the results of the rebuild in this table. One table per DB*/
	IF object_id('dbo.log_Index_rebuilds') IS NULL
	BEGIN
		CREATE TABLE dbo.log_index_rebuild
		(
			log_index_rebuild_id	INT IDENTITY(1,1) NOT NULL,
			tableName				VARCHAR(200) NOT NULL,
			indexName				VARCHAR(200) NOT NULL,
			BeforeRebuildFragment	INT NOT NULL,
			AfterRebuildFragment	INT NOT NULL DEFAULT 0,
			rundate					DATETIME DEFAULT GETDATE(),
		 	CONSTRAINT [PK_log_index_rebuild] PRIMARY KEY CLUSTERED 
			(
				[log_index_rebuild_id] ASC
			)
		)
	END 

	/*Create the loop of fragmented indexes*/
	DECLARE IndexRebuildCursor CURSOR READ_ONLY
	FOR
		/*Get the fragmented indexes that we want to rebuild*/
		SELECT
			OBJECT_NAME(OBJECT_ID) AS TableName,
			SI.NAME AS IndexName,
			AVG_FRAGMENTATION_IN_PERCENT AS AvgPageFragmentation
		FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL , NULL, N'LIMITED') DPS
		INNER JOIN sysindexes SI ON DPS.OBJECT_ID = SI.ID AND DPS.INDEX_ID = SI.INDID
		WHERE AVG_FRAGMENTATION_IN_PERCENT > 10 /*If more the 10% fragmented*/
		AND SI.NAME IS NOT NULL
	/*Put the next set of results into this loop num*/
	OPEN IndexRebuildCursor
		FETCH NEXT FROM IndexRebuildCursor
		INTO @TableName,@indexName,@Fragmentation
	WHILE @@FETCH_STATUS = 0
	BEGIN
			/*Put before values into our log table*/
			INSERT INTO dbo.log_index_rebuild
			(
				tableName,
				indexName,
				BeforeRebuildFragment
			)
			VALUES
			(
				@TableName,
				@indexName,
				@Fragmentation
			)
			
			SET @LogID	=	SCOPE_IDENTITY()
		
			/*Major fragmentation so we need to rebuild it*/
			IF @Fragmentation > 30
			BEGIN
				/*Cannot do online rebuild if table containing index has text type column*/
				IF EXISTS(
							SELECT OBJECT_NAME(c.OBJECT_ID) TableName 
							FROM sys.columns AS c 
							INNER JOIN sys.types AS t ON c.user_type_id=t.user_type_id
							WHERE t.name = 'text' 
							AND OBJECT_NAME(c.OBJECT_ID) = @TableName
						 )	
				BEGIN
					/*Build rebuild statement*/
					SET @SQLStatement	=	'ALTER INDEX '+@indexName+' ON '+@TableName+' REBUILD WITH (FILLFACTOR = 90)'
				END		 
				ELSE
				BEGIN
					/*Build rebuild statement*/
					SET @SQLStatement	=	'ALTER INDEX '+@indexName+' ON '+@TableName+' REBUILD WITH (FILLFACTOR = 90, ONLINE = ON)'
				END
			END
			/*Minor fragmentation so we need to reorganize it*/
			ELSE
			BEGIN
				/*Build rebuild statement*/
				SET @SQLStatement	=	'ALTER INDEX '+@indexName+' ON '+@TableName+' REORGANIZE'
			END

			/*Run the rebuild statement*/	
			EXECUTE(@SQLStatement)
			
			/*Update log with after rebuild value*/
			UPDATE dbo.log_index_rebuild
			SET AfterRebuildFragment	=	DPS.AVG_FRAGMENTATION_IN_PERCENT
			FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL , NULL, N'LIMITED') DPS
			INNER JOIN sysindexes SI ON DPS.OBJECT_ID = SI.ID AND DPS.INDEX_ID = SI.INDID
			WHERE log_index_rebuild_id	=	@LogID
			AND OBJECT_NAME(OBJECT_ID)	=	@TableName
			AND SI.NAME					=	@indexName;
			
			/*put the next set of data into the next loop num*/
			FETCH NEXT FROM IndexRebuildCursor
			INTO @TableName,@indexName,@Fragmentation
	END	

	CLOSE IndexRebuildCursor
	DEALLOCATE IndexRebuildCursor
END
