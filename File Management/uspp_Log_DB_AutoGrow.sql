USE [DBA_Logs]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
----------------------------------------------------------------------------------------------------
-- OBJECT NAME			:	uspp_Log_DB_AutoGrow
--
-- AUTHOR				:	Riken Patel
--
-- INPUTS				:	None
-- OUTPUTS				:	None
-- DEPENDENCIES			:	None
--
-- DESCRIPTION			:	Saves Auto Grow Events in 
--
-- EXAMPLES				:	exec uspp_Log_DB_AutoGrow
----------------------------------------------------------------------------------------------------

ALTER PROC [dbo].[uspp_Log_DB_AutoGrow]

AS

SET NOCOUNT ON


DECLARE @filename NVARCHAR(1000)
DECLARE @bc INT
DECLARE @ec INT
DECLARE @bfn VARCHAR(1000)
DECLARE @efn VARCHAR(10)



/*Get the name of the current default trace*/
SELECT @filename = CAST(value AS NVARCHAR(1000))
FROM sys.fn_trace_getinfo(DEFAULT)
WHERE traceid = 1 AND property = 2



/*separate file name into pieces*/
SET @filename = REVERSE(@filename)
SET @bc = CHARINDEX('.',@filename)
SET @ec = CHARINDEX('_',@filename)+1
SET @efn = REVERSE(SUBSTRING(@filename,1,@bc))
SET @bfn = REVERSE(SUBSTRING(@filename,@ec,LEN(@filename)))

/*set filename without rollover number*/
SET @filename = @bfn + @efn



/*process all trace files and insert data into DB_AutoGrow_Log*/
INSERT INTO DB_AutoGrow_Log (StartTime, EventName, DatabaseName, [FileName], GrowthMB, Duration_Secs)
SELECT	ftg.StartTime,
		te.name,
		DB_NAME(ftg.databaseid),
		ftg.[Filename],
		(ftg.IntegerData*8)/1024.0,
		(ftg.duration)/1000000.0
FROM fn_trace_gettable(@filename, DEFAULT) AS ftg INNER JOIN sys.trace_events AS te ON ftg.EventClass = te.trace_event_id
WHERE	(ftg.EventClass = 92 OR ftg.EventClass = 93) -- Date File Auto-grow, Log File Auto-grow
			AND ftg.StartTime > (SELECT ISNULL(MAX(StartTime), '1900-01-01') FROM DB_AutoGrow_Log)

GO