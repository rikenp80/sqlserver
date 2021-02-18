drop table #io_stats
go

SELECT b.physical_name, b.name, a.num_of_reads, num_of_bytes_read, num_of_writes, num_of_bytes_written
into #io_stats
from sys.dm_io_virtual_file_stats(null, null) a 
INNER JOIN sys.master_files b ON a.database_id = b.database_id and a.file_id = b.file_id

select 
	a.physical_name,
	a.name,
	b.num_of_reads - a.num_of_reads 'num_of_reads',
	(b.num_of_bytes_read - a.num_of_bytes_read)/1024/1024/1024 'GB_read',
	b.num_of_writes - a.num_of_writes 'num_of_writes',
	(b.num_of_bytes_written - a.num_of_bytes_written)/1024/1024/1024 'GB_written'
from io_stats_1 a inner join #io_stats b on a.physical_name = b.physical_name and a.name = b.name
order by (b.num_of_bytes_read - a.num_of_bytes_read) desc