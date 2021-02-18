use distribution
go
select *
from MSdistribution_history
order by time desc

select *
from MSrepl_errors
order by time desc