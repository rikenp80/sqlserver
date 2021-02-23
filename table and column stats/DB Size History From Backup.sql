select database_name, s.backup_start_date,
	(backup_size)/1024/1024/1024 'DB_Space_Used_GB'
from backupset s
--where database_name = ''
order by backup_start_date desc