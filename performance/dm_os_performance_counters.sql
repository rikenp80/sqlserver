use master
go

declare @cntr_value1a decimal(19,2)
declare @cntr_value1b decimal(19,2)

declare @cntr_value2a decimal(19,2)
declare @cntr_value2b decimal(19,2)

declare @seconds decimal(19,2) = 30


select @cntr_value1a = cntr_value
from sys.dm_os_performance_counters
where counter_name = 'Lazy writes/sec'

select @cntr_value1b = cntr_value
from sys.dm_os_performance_counters
where counter_name = 'Free list stalls/sec'

waitfor delay '00:00:30'

select @cntr_value2a = cntr_value
from sys.dm_os_performance_counters
where counter_name = 'Lazy writes/sec'

select @cntr_value2b = cntr_value
from sys.dm_os_performance_counters
where counter_name = 'Free list stalls/sec'    

select (@cntr_value2a - @cntr_value1a)/@seconds 'Lazy writes/sec'
select (@cntr_value2b - @cntr_value1b)/@seconds 'Free list stalls/sec'