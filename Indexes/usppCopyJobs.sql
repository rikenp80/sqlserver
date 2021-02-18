USE [master]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
----------------------------------------------------------------------------------------------------
-- OBJECT NAME			:	usppCopyJobs
--
-- AUTHOR				:	Riken Patel
--
-- INPUTS				:	@RemoteServer - server from which jobs are to be copied from
--
-- OUTPUTS				:	None
-- DEPENDENCIES			:	None
--
-- DESCRIPTION			:	Copy jobs from the server specified in the @RemoteServer parameter and copy
--							them to the server on which the procedure is
--
-- EXAMPLES				:	EXEC usppCopyJobs 'PTGWINSQL01\OMNIBUSDEV'
----------------------------------------------------------------------------------------------------

ALTER PROC usppCopyJobs @RemoteServer VARCHAR(500)

AS

SET NOCOUNT ON


DECLARE @SQL					VARCHAR(5000),
		@job_name				VARCHAR(500),
		@schedule_name			VARCHAR(500),
		@description			NVARCHAR(1024),
		@start_step_id			INT,
		@notify_level_eventlog	INT,
		@notify_level_email		INT,
		@operator_name			VARCHAR(500),
		@category_name			VARCHAR(500)


/*------------------------------------------------------------------------------------------------------------------------
get job details from the remote server which are to be copied
------------------------------------------------------------------------------------------------------------------------*/
SET @SQL =
		"
		INSERT INTO #sysjobs_Remote
		SELECT
			j.name,
			j.[description],
			j.start_step_id,
			j.notify_level_eventlog,
			j.notify_level_email,
			o.name,
			c.name
		FROM [" + @RemoteServer + "].msdb.dbo.sysjobs j
			LEFT JOIN [" + @RemoteServer + "].msdb.dbo.sysoperators o ON j.notify_email_operator_id = o.id
			LEFT JOIN [" + @RemoteServer + "].msdb.dbo.syscategories c ON j.category_id = c.category_id
		"


CREATE TABLE #sysjobs_Remote
			(
			job_name				VARCHAR(500),
			[description]			NVARCHAR(1024),
			start_step_id			INT,
			notify_level_eventlog	INT,
			notify_level_email		INT,
			operator_name			VARCHAR(500),
			category_name			VARCHAR(500)
			)

EXEC (@SQL)



/*------------------------------------------------------------------------------------------------------------------------
delete jobs from the local server that no longer exist on remote server or have been changed
------------------------------------------------------------------------------------------------------------------------*/
CREATE TABLE #jobs_to_delete (job_name VARCHAR(500))


--get jobs that no longer exist on principal
INSERT INTO #jobs_to_delete (job_name)
SELECT j.name
FROM msdb.dbo.sysjobs j
WHERE NOT EXISTS (SELECT * FROM #sysjobs_Remote t WHERE j.name = t.job_name)


--get jobs that have been changed and need to be dropped and recreated
INSERT INTO #jobs_to_delete (job_name)
SELECT j.name
FROM msdb.dbo.sysjobs j 
		INNER JOIN #sysjobs_Remote t on j.name = t.job_name
		LEFT JOIN msdb.dbo.sysoperators o ON j.notify_email_operator_id = o.id
		LEFT JOIN msdb.dbo.syscategories c ON j.category_id = c.category_id		
WHERE	j.start_step_id <> t.start_step_id
		OR ISNULL(j.[description], '') <> ISNULL(t.[description], '')
		OR j.notify_level_eventlog <> t.notify_level_eventlog
		OR j.notify_level_email <> t.notify_level_email
		OR ISNULL(o.name, '') <> ISNULL(t.operator_name, '')
		OR ISNULL(c.name, '') <> ISNULL(t.category_name, '')
		

		
--remove "Sync Changes to Mirror" job as this should not be synced
DELETE FROM #jobs_to_delete WHERE job_name = 'Sync Changes to Mirror'

--drop jobs
WHILE EXISTS (SELECT * FROM #jobs_to_delete)
BEGIN

	--get next record from #jobs_to_delete
	SELECT @job_name = MIN(job_name) FROM #jobs_to_delete
	
	
	--execute script to delete job
	PRINT 'Deleting Job: ' + @job_name
	EXEC msdb.dbo.sp_delete_job @job_name = @job_name, @delete_history = 0, @delete_unused_schedule = 0
	
	
	--delete processed record from temp table
	DELETE FROM #jobs_to_delete WHERE job_name = @job_name

END



/*------------------------------------------------------------------------------------------------------------------------
loop through each record in #sysjobs_Remote and add job
------------------------------------------------------------------------------------------------------------------------*/

WHILE EXISTS (SELECT * FROM #sysjobs_Remote)
BEGIN
					
	--get next record from #sysjobs_Remote
	SELECT TOP 1
		@job_name				= job_name,
		@description			= [description],
		@start_step_id			= start_step_id,
		@notify_level_eventlog	= notify_level_eventlog,
		@notify_level_email		= notify_level_email,
		@operator_name			= operator_name,
		@category_name			= category_name
	FROM #sysjobs_Remote

	
	IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = @job_name)
	BEGIN
		
		--execute script to create job
		PRINT 'Adding Job: ' + @job_name

		IF NOT EXISTS (SELECT * FROM msdb.dbo.syscategories WHERE category_class = 1 AND category_type = 1 AND name = @category_name)
		BEGIN
			EXEC msdb.dbo.sp_add_category @class='JOB', @type='LOCAL', @name=@category_name
		END

		EXEC msdb.dbo.sp_add_job
				@job_name = @job_name,
				@enabled = 1,
				@description = @description,
				@start_step_id = @start_step_id,
				@category_name = @category_name,
				@owner_login_name = 'NT AUTHORITY\SYSTEM',
				@notify_level_eventlog = @notify_level_eventlog,
				@notify_level_email = @notify_level_email,				
				@notify_email_operator_name = @operator_name

		
		--add job to local server
		EXEC msdb.dbo.sp_add_jobserver @job_name = @job_name

	END


	--delete processed record from temp table
	DELETE FROM #sysjobs_Remote WHERE job_name = @job_name
	
END


/*run procedure to determine if the added jobs should be enabled or disabled*/
EXEC DBA_Logs.dbo.uspu_ChangeJobStatus_AfterFailover


GO

