SELECT	xml_data,
		xml_data.value('(/event/timestamp)[1]','datetime'),
		(xml_data.value('(/event/data[@name=''duration'']/value)[1]','bigint'))/1000000 'duraton_secs',
		(xml_data.value('(/event/data[@name=''duration'']/value)[1]','bigint'))/1000000/60 'duraton_mins',
		xml_data.value('(/event/action[@name=''plan_handle'']/value)[1]','varchar(5000)'),
		xml_data.value('(/event/data[@name=''statement'']/value)[1]','varchar(4000)')
		--xml_data.value('(/event/action[@name=''sql_text'']/value)[1]','varchar(max)')
FROM
	(
	SELECT object_name 'event', CONVERT(xml, event_data) 'xml_data'
	FROM sys.fn_xe_file_target_read_file ('E:\ExtendedEventFiles\errors*.xel', NULL, NULL, NULL)
	) AS a
where (xml_data.value('(/event/data[@name=''statement'']/value)[1]','varchar(4000)')) like '%REEVAL%'
order by xml_data.value('(/event/data[@name=''duration'']/value)[1]','bigint') desc


declare @plan_handle_varbinary varbinary(64)
select @plan_handle_varbinary = convert(varbinary, 0x05000900872ca066c09e2d3d0300000001000000000000000000000000000000000000000000000000000000)
select @plan_handle_varbinary

--select * from sys.dm_exec_query_plan (@plan_handle_varbinary) 
select * from sys.dm_exec_query_stats where plan_handle = @plan_handle_varbinary

select * from sys.databases order by database_id


