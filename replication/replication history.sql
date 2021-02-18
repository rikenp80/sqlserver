use distribution
go

select 
a.name,
a.publication,
h.time,
h.delivery_rate,
h.delivery_latency,
h.current_delivery_rate,
h.current_delivery_latency,
h.delivered_transactions,
h.delivered_commands,
h.total_delivered_commands,
h.average_commands,
h.comments
--,h.*, a.*
from MSdistribution_history h inner join MSdistribution_agents a on h.agent_id = a.id
--where h.time > '2019-05-15 15:00'
order by h.time desc

select *
from MSrepl_errors
order by time desc