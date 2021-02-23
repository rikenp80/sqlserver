CREATE TABLE [QueryExecutionStats]
	(
	database_name				VARCHAR(100)		NULL,
	cached_time					DATETIME2(3)		NOT NULL,
	last_execution_time			DATETIME2(3)	NULL,
	execution_count				BIGINT				NULL,
	executions_per_sec			INT             NULL,
	cpu_time_per_second			DECIMAL(9,4)	NULL,
	average_cpu_time_secs		DECIMAL(9,4)	NULL,
	average_elapsed_time_secs	DECIMAL(9,4)	NULL,
	average_logical_reads		BIGINT				NULL,
	average_logical_writes		BIGINT				NULL,
	average_physical_reads		BIGINT				NULL,
	total_physical_reads		BIGINT				NULL,
	query_text					NVARCHAR(MAX)	NULL,
	query_plan					XML				NULL,
	sql_handle					VARBINARY(64)	NULL
	)
GO

create clustered index CIX_QueryExecutionStats_cached_time on QueryExecutionStats (cached_time) with fillfactor= 95
create index IX_QueryExecutionStats_total_physical_reads on QueryExecutionStats (total_physical_reads) with fillfactor= 90
create index IX_QueryExecutionStats_average_physical_reads on QueryExecutionStats (average_physical_reads) with fillfactor= 90
create index IX_QueryExecutionStats_last_execution_time on QueryExecutionStats (last_execution_time) with fillfactor= 95
create index IX_QueryExecutionStats_sql_handle on QueryExecutionStats (sql_handle) with fillfactor= 90

-----------------------------------------------------------------------------------------------------------------------------------------------


USE [msdb]
GO

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job
		@job_name=N'Log Query Execution Stats', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa',
		@job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Log Stats', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'IF OBJECT_ID(''tempdb..#new_data'') IS NOT NULL DROP TABLE #new_data

CREATE TABLE #new_data
		        (
		        database_name			VARCHAR(100)		NULL,
		        cached_time				DATETIME2(3)		NOT NULL,
                last_execution_time			DATETIME2(3)	NULL,
		        execution_count				BIGINT				NULL,
                executions_per_sec			INT             NULL,
				cpu_time_per_second			DECIMAL(9,4)	NULL,
		        average_cpu_time_secs		DECIMAL(9,4)	NULL,
				average_elapsed_time_secs	DECIMAL(9,4)	NULL,
		        average_logical_reads		BIGINT				NULL,
		        average_logical_writes		BIGINT				NULL,
		        average_physical_reads		BIGINT				NULL,
				total_physical_reads		BIGINT				NULL,
				query_text					NVARCHAR(MAX)	NULL,
		        query_plan					XML				NULL,
				sql_handle					VARBINARY(64)	NULL
		        )

INSERT INTO #new_data
SELECT
    db_name(qp.dbid),
    qs.creation_time,
	last_execution_time,
	execution_count,
	CASE WHEN DATEDIFF(second, creation_time, GETDATE()) < 1 THEN cast(execution_count as decimal) ELSE
		cast(execution_count as decimal) / cast(DATEDIFF(second, creation_time, GETDATE()) as decimal) END ''executions_per_sec'',

	(CASE WHEN DATEDIFF(second, creation_time, GETDATE()) < 1 THEN cast(execution_count as decimal) ELSE
	cast(execution_count as decimal) / cast(DATEDIFF(second, creation_time, GETDATE()) as decimal) END) * ((qs.total_worker_time/(nullif(qs.execution_count,0)))/1000000.0) ''cpu_time_per_second'',

	(qs.total_worker_time/(nullif(qs.execution_count,0)))/1000000.0 ''average_cpu_time_secs'',
	(qs.total_elapsed_time/(nullif(qs.execution_count,0)))/1000000.0 ''average_elapsed_time_secs'',
	qs.total_logical_reads/nullif(qs.execution_count,0) ''average_logical_reads'',
	qs.total_logical_writes/nullif(qs.execution_count,0) ''average_logical_writes'',
	qs.total_physical_reads/nullif(qs.execution_count,0) ''average_physical_reads'',
	qs.total_physical_reads,
	qt.text,
	query_plan,
    qs.sql_handle    
FROM sys.dm_exec_query_stats (nolock) AS qs 
	CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
	CROSS APPLY sys.dm_exec_query_plan (qs.plan_handle) as qp
WHERE execution_count > 0 and qs.total_physical_reads > 0
	and qp.dbid not in (32767,1)
	and db_name(qp.dbid) not in (''distribution'')

--SELECT * FROM #new_data
/*--------------------------------------------------------------------------
update stats for existing cached plans
--------------------------------------------------------------------------*/
UPDATE q
SET 
	last_execution_time = n.last_execution_time,
	execution_count = n.execution_count,
	executions_per_sec = n.executions_per_sec,
	cpu_time_per_second = n.cpu_time_per_second,
	average_cpu_time_secs = n.average_cpu_time_secs,
	average_elapsed_time_secs = n.average_elapsed_time_secs,
	average_logical_reads = n.average_logical_reads,
	average_logical_writes = n.average_logical_writes,
	average_physical_reads = n.average_physical_reads,
	total_physical_reads = n.total_physical_reads
					    
FROM QueryExecutionStats q
	INNER JOIN #new_data n ON q.sql_handle = n.sql_handle AND q.cached_time = n.cached_time



/*--------------------------------------------------------------------------
insert newly cached plans into table
--------------------------------------------------------------------------*/
INSERT INTO QueryExecutionStats
SELECT *
FROM #new_data n
    WHERE NOT EXISTS (SELECT * FROM QueryExecutionStats q WHERE q.sql_handle = n.sql_handle AND q.cached_time = n.cached_time)



/*--------------------------------------------------------------------------
delete old data
--------------------------------------------------------------------------*/
DELETE FROM QueryExecutionStats WHERE last_execution_time < DATEADD(MM,-3,GETDATE())', 

		@database_name=N'dbManagement', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback


EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback


EXEC @ReturnCode = msdb.dbo.sp_attach_schedule
		@job_id=@jobId,
		@schedule_name=N'CollectorSchedule_Every_10min'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback


EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback


COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

