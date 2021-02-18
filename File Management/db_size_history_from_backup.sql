with datasize (backup_start_date, DataSize_GB, Last_DataSize_GB)
as
(
select b.backup_start_date,
	sum(f.backup_size/1024/1024/1024) 'DataSize_GB',
	LAG((sum(f.backup_size/1024/1024/1024)),1,0) over (order by (b.backup_start_date)) 'Last_DataSize_GB'
from backupset b left join backupfile f on b.backup_set_id = f.backup_set_id
where database_name = ''
	and type = 'D'
	and f.file_type = 'D'
	--and f.logical_name = ''
group by b.backup_start_date
)

select backup_start_date, DataSize_GB, DataSize_GB - Last_DataSize_GB 'Difference'
from datasize
order by backup_start_date desc