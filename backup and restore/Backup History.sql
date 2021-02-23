USE [msdb]
select	database_name,
		recovery_model,
		case	when type = 'D' then 'Full'
				when type = 'I' then 'Differential'
				when type = 'L' then 'Log'
		end 'backup_type',
		backup_start_date,
		backup_finish_date,
		user_name,
		name 'backup_application',
		backup_size/1024/1024/1024,
		compressed_backup_size/1024/1024/1024,
		m.physical_device_name
from backupset b inner join backupmediafamily m on b.media_set_id = m.media_set_id
order by b.backup_start_date desc

