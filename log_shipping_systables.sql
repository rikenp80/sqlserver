USE msdb
GO

SELECT TOP 10000 * FROM log_shipping_monitor_history_detail WHERE agent_id = 'A238EA7A-2896-40F5-9F22-5A83033D7D87' ORDER BY log_time desc

SELECT TOP 1000 * FROM log_shipping_monitor_secondary WHERE secondary_database = 'iHerb_Rewards'
SELECT TOP 1000 * FROM dbo.log_shipping_secondary_databases WHERE secondary_database = 'iHerb_Rewards'

select * from log_shipp