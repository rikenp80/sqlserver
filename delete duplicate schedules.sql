--EXEC usppCopySchedules 'PTGMAMSQLDEV01\PP1'

--SELECT * FROM msdb.dbo.sysschedules ORDER BY name
--SELECT * FROM msdb.dbo.sysjobschedules ORDER BY schedule_id


DECLARE @DuplicateSchedules TABLE (ScheduleName VARCHAR(500))
INSERT INTO @DuplicateSchedules
SELECT name
FROM msdb.dbo.sysschedules
GROUP BY name
HAVING COUNT(*) > 1


DECLARE @DuplicateScheduleIDs TABLE (ScheduleID INT)
INSERT INTO @DuplicateScheduleIDs
SELECT a.schedule_id
FROM msdb.dbo.sysschedules a INNER JOIN @DuplicateSchedules d ON a.name = d.ScheduleName
WHERE NOT EXISTS (SELECT * FROM msdb.dbo.sysjobschedules b WHERE a.schedule_id = b.schedule_id)


DECLARE @ScheduleID INT

WHILE EXISTS (SELECT * FROM @DuplicateScheduleIDs)
BEGIN
	SELECT @ScheduleID = MIN(ScheduleID) FROM @DuplicateScheduleIDs
	
	PRINT @ScheduleID
	EXEC msdb.dbo.sp_delete_schedule @schedule_id = @ScheduleID, @force_delete = 1

	DELETE FROM @DuplicateScheduleIDs WHERE ScheduleID = @ScheduleID
END