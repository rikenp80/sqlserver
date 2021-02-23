USE [msdb]
GO
select r.*, b.backup_finish_date, b.server_name
from restorehistory r inner join backupset b on r.backup_set_id = b.backup_set_id
--where destination_database_name = ''
order by restore_date desc


