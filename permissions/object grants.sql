SELECT
  (
    dp.state_desc + ' ' +
    dp.permission_name collate latin1_general_cs_as + 
    ' ON ' + '[' + s.name + ']' + '.' + '[' + o.name + ']' +
    ' TO ' + '[' + dpr.name + ']'
  ) AS GRANT_STMT,
  dp.permission_name,
  dp.state_desc,
  s.name 'schema_name',
  o.name 'object_name',
  dpr.name 'db_principal'
FROM sys.database_permissions AS dp
  INNER JOIN sys.objects AS o ON dp.major_id=o.object_id
  INNER JOIN sys.schemas AS s ON o.schema_id = s.schema_id
  INNER JOIN sys.database_principals AS dpr ON dp.grantee_principal_id=dpr.principal_id
WHERE 1=1
    AND o.name IN ('TBL_OrderDelay', 'TBL_Orders')
ORDER BY dpr.name