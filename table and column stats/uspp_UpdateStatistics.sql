USE [DBA_Logs]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
----------------------------------------------------------------------------------------------------
-- OBJECT NAME			:	uspp_UpdateStatistics
--
-- AUTHOR				:	Riken Patel
--
-- INPUTS				:	None
-- OUTPUTS				:	None
-- DEPENDENCIES			:	None
--
-- DESCRIPTION			:	Update statistics in all databases
--
-- EXAMPLES (optional)  :	EXEC uspp_UpdateStatistics
----------------------------------------------------------------------------------------------------

ALTER PROC uspp_UpdateStatistics

AS


SET NOCOUNT ON


DECLARE @Databases TABLE
		(
		DatabaseID		INT NOT NULL,
		DatabaseName	VARCHAR(500) NOT NULL,
		DatabaseType	VARCHAR(10) NOT NULL,
		RecoveryModel	VARCHAR(60) NOT NULL
		)
INSERT INTO @Databases
EXEC uspp_GetDatabases 0, NULL, NULL, 'model'


/*------------------------------------------------------------------------------------------------------------------------------------------------------
Loop through each database in @Databases and update the statistics
------------------------------------------------------------------------------------------------------------------------------------------------------*/
DECLARE @Current_DBName VARCHAR(500)
DECLARE @SQL VARCHAR(500)

SELECT @Current_DBName = MIN(DatabaseName) FROM @Databases


WHILE @Current_DBName IS NOT NULL
BEGIN
	
	SET @SQL = 'EXEC ' + @Current_DBName + '.sys.sp_updatestats'
	EXEC(@SQL)

	DELETE FROM @Databases WHERE DatabaseName = @Current_DBName

	SELECT @Current_DBName = MIN(DatabaseName) FROM @Databases

END

GO