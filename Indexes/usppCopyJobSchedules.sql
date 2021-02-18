USE [master]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
----------------------------------------------------------------------------------------------------
-- OBJECT NAME			:	usppCopyJobSchedules
--
-- AUTHOR				:	Riken Patel
--
-- INPUTS				:	@RemoteServer - server from which jobs are to be copied from
--
-- OUTPUTS				:	None
-- DEPENDENCIES			:	None
--
-- DESCRIPTION			:	Copy job steps from the server specified in the @RemoteServer parameter and copy
--							them to the server on which the procedure is
--
-- EXAMPLES				:	EXEC usppCopyJobSchedules 'PTGWINSQL01\OMNIBUSDEV'
----------------------------------------------------------------------------------------------------

ALTER PROC usppCopyJobSchedules @RemoteServer VARCHAR(500)

AS

SET NOCOUNT ON


DECLARE @SQL					VARCHAR(5000),
		@job_name				VARCHAR(500),
		@schedule_name			VARCHAR(500)


/*------------------------------------------------------------------------------------------------------------------------
get job schedule details from the remote server which are to be copied
------------------------------------------------------------------------------------------------------------------------*/
SET @SQL =
		"
		INSERT INTO #sysjobschedules_Remote
		SELECT
			a.name,
			c.name
		FROM [" + @RemoteServer + "].msdb.dbo.sysjobs a
			INNER JOIN [" + @RemoteServer + "].msdb.dbo.sysjobschedules b ON a.job_id = b.job_id
			INNER JOIN [" + @RemoteServer + "].msdb.dbo.sysschedules c ON b.schedule_id = c.schedule_id
		"


CREATE TABLE #sysjobschedules_Remote
			(
			job_name		VARCHAR(500),
			schedule_name	VARCHAR(500)
			)

EXEC (@SQL)



/*------------------------------------------------------------------------------------------------------------------------
delete job schedules from the local server that no longer exist on remote server
------------------------------------------------------------------------------------------------------------------------*/
CREATE TABLE #schedules_to_delete (job_name VARCHAR(500), schedule_name VARCHAR(500))


--get schedules that no longer exist on principal
INSERT INTO #schedules_to_delete (job_name, schedule_name)
SELECT j.name, s.name
FROM msdb.dbo.sysjobs j
	INNER JOIN msdb.dbo.sysjobschedules js ON j.job_id = js.job_id
	INNER JOIN msdb.dbo.sysschedules s ON js.schedule_id = s.schedule_id
WHERE NOT EXISTS (SELECT * FROM #sysjobschedules_Remote t WHERE j.name = t.job_name AND s.name = t.schedule_name)



--drop schedules
WHILE EXISTS (SELECT * FROM #schedules_to_delete)
BEGIN

	--get next record from #schedules_to_delete
	SELECT TOP 1 @job_name = job_name, @schedule_name = schedule_name FROM #schedules_to_delete
	
	
	--execute script to delete schedule
	PRINT 'Deleting Job Schedule: ' + @job_name + ' - ' + @schedule_name
	EXEC msdb.dbo.sp_detach_schedule @job_name = @job_name, @schedule_name = @schedule_name, @delete_unused_schedule=0
	
	
	--delete processed record from temp table
	DELETE FROM #schedules_to_delete WHERE job_name = @job_name AND schedule_name = @schedule_name

END



/*------------------------------------------------------------------------------------------------------------------------
loop through each record in #sysjobschedules_Remote and add schedule
------------------------------------------------------------------------------------------------------------------------*/
WHILE EXISTS (SELECT * FROM #sysjobschedules_Remote)
BEGIN
	
	--get next record from #sysjobschedules_Remote
	SELECT TOP 1
		@job_name = job_name,
		@schedule_name = schedule_name
	FROM #sysjobschedules_Remote
	

	IF NOT EXISTS	(
					SELECT * 
					FROM msdb.dbo.sysjobs j
						INNER JOIN msdb.dbo.sysjobschedules js ON j.job_id = js.job_id
						INNER JOIN msdb.dbo.sysschedules s ON js.schedule_id = s.schedule_id
					WHERE j.name = @job_name AND s.name = @schedule_name 
					)
	BEGIN	
		PRINT '  Adding Job Schedule: ' + @job_name + ' - ' + @schedule_name

		EXEC msdb.dbo.sp_attach_schedule
				@job_name = @job_name,
				@schedule_name = @schedule_name
	END


	--delete processed record from temp table
	DELETE FROM #sysjobschedules_Remote WHERE job_name = @job_name AND schedule_name = @schedule_name 
	
END

GO