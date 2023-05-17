SELECT SCHEMA_NAME(t.schema_id) AS SchemaName, t.name AS TableName, i.name AS IndexName, 
    p.partition_number AS PartitionNumber, f.name AS PartitionFunctionName, p.rows AS Rows, rv.value AS BoundaryValue, 
CASE WHEN ISNULL(rv.value, rv2.value) IS NULL THEN 'N/A' 
ELSE
    CASE WHEN f.boundary_value_on_right = 0 AND rv2.value IS NULL THEN '>=' 
        WHEN f.boundary_value_on_right = 0 THEN '>' 
        ELSE '>=' 
    END + ' ' + ISNULL(CONVERT(varchar(64), rv2.value), 'Min Value') + ' ' + 
        CASE f.boundary_value_on_right WHEN 1 THEN 'and <' 
                ELSE 'and <=' END 
        + ' ' + ISNULL(CONVERT(varchar(64), rv.value), 'Max Value') 
END AS TextComparison
FROM sys.tables AS t  
JOIN sys.indexes AS i  
    ON t.object_id = i.object_id  
JOIN sys.partitions AS p  
    ON i.object_id = p.object_id AND i.index_id = p.index_id   
JOIN  sys.partition_schemes AS s   
    ON i.data_space_id = s.data_space_id  
JOIN sys.partition_functions AS f   
    ON s.function_id = f.function_id  
LEFT JOIN sys.partition_range_values AS r   
    ON f.function_id = r.function_id and r.boundary_id = p.partition_number  
LEFT JOIN sys.partition_range_values AS rv
    ON f.function_id = rv.function_id
    AND p.partition_number = rv.boundary_id     
LEFT JOIN sys.partition_range_values AS rv2
    ON f.function_id = rv2.function_id
    AND p.partition_number - 1= rv2.boundary_id
WHERE 
    t.name = 'PartitionTable'
    AND i.type <= 1 
ORDER BY t.name, p.partition_number;


select * from sys.partition_schemes
select * from sys.partition_functions
select * from sys.partition_range_values
select * from sys.partition_parameters

select * from sys.dm_db_partition_stats