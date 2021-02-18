USE [master]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
----------------------------------------------------------------------------------------------------
-- OBJECT NAME			:	usppCopyJobSteps
--
-- AUTHOR				:	Riken Patel
--
-- INPUTS				:	@RemoteServer - server from which jobs steps are to be copied from
--
-- OUTPUTS				:	None
-- DEPENDENCIES			:	None
--
-- DESCRIPTION			:	Copy job steps from the server specified in the @RemoteServer parameter and copy
--							them to the server on which the procedure is
--
-- EXAMPLES				:	EXEC usppCopyJobSteps 'PTGWINSQL01\OMNIBUSDEV'
----------------------------------------------------------------------------------------------------

ALTER PROC usppCopyJobSteps @RemoteServer VARCHAR(500)

AS

SET NOCOUNT ON


DECLARE @SQL					VARCHAR(5000),
		@job_name				VARCHAR(500),		
		@step_id				INT,
		@step_name				VARCHAR(500),
		@cmdexec_success_code	INT,
		@retry_attempts			INT,
		@retry_interval			INT,
		@os_run_priority		INT,
		@flags					INT,
		@subsystem				NVARCHAR(80),
		@command				NVARCHAR(MAX),
		@on_success_action		TINYINT,
		@on_success_step_id		INT, 
		@on_fail_action			TINYINT,
		@on_fail_step_id		INT,
		@database_name			VARCHAR(500),
		@RemoteServer_Instance	VARCHAR(500),
		@LocalServer_Instance	VARCHAR(500)



/*------------------------------------------------------------------------------------------------------------------------
get the local and remote server instance name
------------------------------------------------------------------------------------------------------------------------*/
SELECT @LocalServer_Instance = @@SERVERNAME


CREATE TABLE #RemoteServer_Instance (RemoteServer_Instance sql_variant)
EXEC ("INSERT INTO #RemoteServer_Instance SELECT * FROM OPENQUERY([" + @RemoteServer + "],'" + "SELECT @@SERVERNAME')")

SELECT @RemoteServer_Instance = CAST(RemoteServer_Instance AS VARCHAR(500)) FROM #RemoteServer_Instance



/*------------------------------------------------------------------------------------------------------------------------
get job step details from the remote server which are to be copied
------------------------------------------------------------------------------------------------------------------------*/
SET @SQL =
		"
		INSERT INTO #sysjobsteps_Remote
		SELECT
			j.name,
			jst.step_id,
			jst.step_name,
			jst.cmdexec_success_code,
			jst.retry_attempts,
			jst.retry_interval,
			jst.os_run_priority,
			jst.flags,
			jst.subsystem,
			jst.command,
			jst.on_success_action,
			jst.on_success_step_id, 
			jst.on_fail_action,
			jst.on_fail_step_id,
			jst.database_name
		FROM [" + @RemoteServer + "].msdb.dbo.sysjobs j
			INNER JOIN [" + @RemoteServer + "].msdb.dbo.sysjobsteps jst ON j.job_id = jst.job_id
		"


CREATE TABLE #sysjobsteps_Remote
			(
			job_name				VARCHAR(500),
			step_id					INT,
			step_name				VARCHAR(500),
			cmdexec_success_code	INT,
			retry_attempts			INT,
			retry_interval			INT,
			os_run_priority			INT,
			flags					INT,
			subsystem				NVARCHAR(80),
			command					NVARCHAR(MAX),
			on_success_action		TINYINT,
			on_success_step_id		INT, 
			on_fail_action			TINYINT,
			on_fail_step_id			INT,
			database_name			VARCHAR(500)
			)

EXEC (@SQL)



/*------------------------------------------------------------------------------------------------------------------------
delete job steps from the local server that no longer exist on remote server or have been changed
------------------------------------------------------------------------------------------------------------------------*/
CREATE TABLE #steps_to_delete (job_name VARCHAR(500), step_id INT, step_name VARCHAR(500))


--get steps that no longer exist on principal
INSERT INTO #steps_to_delete (job_name, step_id, step_name)
SELECT j.name, jst.step_id, jst.step_name
FROM msdb.dbo.sysjobsteps jst
	INNER JOIN msdb.dbo.sysjobs j ON j.job_id = jst.job_id
WHERE NOT EXISTS (SELECT * FROM #sysjobsteps_Remote t WHERE j.name = t.job_name AND jst.step_name = t.step_name)


--get steps that have been changed and need to be dropped and recreated
INSERT INTO #steps_to_delete (job_name, step_id, step_name)
SELECT j.name, jst.step_id, jst.step_name
FROM msdb.dbo.sysjobsteps jst
	INNER JOIN msdb.dbo.sysjobs j ON j.job_id = jst.job_id
	INNER JOIN #sysjobsteps_Remote t ON j.name = t.job_name AND jst.step_name = t.step_name
WHERE	jst.cmdexec_success_code <> t.cmdexec_success_code
		OR jst.retry_attempts <> t.retry_attempts
		OR jst.retry_interval <> t.retry_interval
		OR jst.os_run_priority <> t.os_run_priority
		OR jst.flags <> t.flags
		OR ISNULL(jst.subsystem, '') <> ISNULL(t.subsystem, '')
		OR jst.on_success_action <> t.on_success_action
		OR jst.on_success_step_id <> t.on_success_step_id
		OR jst.on_fail_action <> t.on_fail_action
		OR jst.on_fail_step_id <> t.on_fail_step_id
		OR ISNULL(jst.database_name, '') <> ISNULL(t.database_name, '')
		OR ISNULL(REPLACE(jst.command, @LocalServer_Instance, @RemoteServer_Instance), '') <> ISNULL(t.command, '')
		OR (jst.command LIKE '%' + @RemoteServer_Instance + '%' AND ISNULL(jst.command, '') = ISNULL(t.command, ''))



--remove "Sync Changes to Mirror" job as this should not be synced
DELETE FROM #steps_to_delete WHERE job_name = 'Sync Changes to Mirror'

--drop steps
WHILE EXISTS (SELECT * FROM #steps_to_delete)
BEGIN

	--get next record from #steps_to_delete
	SELECT TOP 1 @job_name = job_name, @step_id = step_id, @step_name = step_name FROM #steps_to_delete
	
	
	--execute script to delete job step
	PRINT 'Deleting Step: ' + @job_name + ' - ' + @step_name
	EXEC msdb.dbo.sp_delete_jobstep @job_name = @job_name, @step_id = @step_id
	
	
	--delete processed record from temp table
	DELETE FROM #steps_to_delete WHERE job_name = @job_name AND step_id = @step_id

END



/*------------------------------------------------------------------------------------------------------------------------
loop through each record in #sysjobsteps_Remote and add job step
------------------------------------------------------------------------------------------------------------------------*/
WHILE EXISTS (SELECT * FROM #sysjobsteps_Remote)
BEGIN
	
	--get next record from #sysjobsteps_Remote
	SELECT TOP 1
		@job_name = job_name,
		@step_id = step_id,
		@step_name = step_name,
		@cmdexec_success_code = cmdexec_success_code,
		@retry_attempts = retry_attempts,
		@retry_interval = retry_interval,
		@os_run_priority = os_run_priority,
		@flags = flags,
		@subsystem = subsystem,
		@command = command,
		@on_success_action = on_success_action,
		@on_success_step_id = on_success_step_id,
		@on_fail_action = on_fail_action,
		@on_fail_step_id = on_fail_step_id,
		@database_name = database_name
	FROM #sysjobsteps_Remote
	

	IF NOT EXISTS	(
					SELECT * 
					FROM msdb.dbo.sysjobs j
						INNER JOIN msdb.dbo.sysjobsteps jst ON j.job_id = jst.job_id
					WHERE j.name = @job_name AND jst.step_name = @step_name 
					)
	BEGIN	
		PRINT 'Adding Step: ' + @job_name + ' - ' + @step_name

		--replace remote server name with local server name in command string
		SET @command = REPLACE(@command, @RemoteServer_Instance, @LocalServer_Instance)

		EXEC msdb.dbo.sp_add_jobstep
				@job_name = @job_name,
				@step_name = @step_name,
				@step_id = @step_id,
				@cmdexec_success_code = @cmdexec_success_code, 
				@on_success_action = @on_success_action,
				@on_success_step_id = @on_success_step_id,
				@on_fail_action = @on_fail_action,
				@on_fail_step_id = @on_fail_step_id,
				@retry_attempts = @retry_attempts,
				@retry_interval = @retry_interval,
				@os_run_priority = @os_run_priority,
				@subsystem = @subsystem,
				@command = @command,
				@database_name = @database_name,
				@flags = @flags
	END


	--delete processed record from temp table
	DELETE FROM #sysjobsteps_Remote WHERE job_name = @job_name AND step_name = @step_name 
	
END

GO