USE [msdb]
select database_name, recovery_model, backup_size, type, backup_start_date, backup_finish_date, user_name, name
from backupset
--where type = 'L'
order by backup_start_date desc