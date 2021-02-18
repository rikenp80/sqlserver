SELECT *
FROM sys.filegroups fg
    inner JOIN sys.allocation_units i ON fg.data_space_id = i.data_space_id
    inner join sys.partitions p on p.partition_id = i.container_id
    INNER JOIN sys.objects o ON p.object_id = o.object_id
WHERE fg.data_space_id = 2
