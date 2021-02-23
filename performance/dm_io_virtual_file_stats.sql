SELECT 
io_stall_read_ms/num_of_reads 'avg_io_stall_read_ms'
,num_of_bytes_read/io_stall_read_ms 'avg_num_of_bytes_read_per_stall_ms'
,io_stall_write_ms/num_of_writes 'avg_io_stall_write_ms'
,*
from sys.dm_io_virtual_file_stats(null, null) a 
INNER JOIN sys.master_files b ON a.database_id = b.database_id and a.file_id = b.file_id
--ORDER BY 



