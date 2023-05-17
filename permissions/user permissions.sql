
USE RCA_Tms_Amazon
GO

SELECT roles.name 'rolename', roles.owning_principal_id, users.name 'username', *
FROM sys.database_principals AS users 
	LEFT JOIN sys.database_role_members rm ON rm.member_principal_id = users.principal_id
	LEFT JOIN sys.database_principals roles ON rm.role_principal_id = roles.principal_id
WHERE users.type <> 'R'
ORDER BY users.name
	
    
SELECT    roles.principal_id                            AS RolePrincipalID
    ,    roles.name                                    AS RolePrincipalName
    ,    database_role_members.member_principal_id    AS MemberPrincipalID
    ,    members.name                                AS MemberPrincipalName
FROM sys.database_role_members AS database_role_members  
JOIN sys.database_principals AS roles  
    ON database_role_members.role_principal_id = roles.principal_id  
JOIN sys.database_principals AS members  
    ON database_role_members.member_principal_id = members.principal_id;  
GO

select * from sys.server_principals order by name


SELECT pr.principal_id, pr.name, pr.type_desc,   
    pr.authentication_type_desc, pe.state_desc,   
    pe.permission_name, s.name + '.' + o.name AS ObjectName  
FROM sys.database_principals AS pr  
JOIN sys.database_permissions AS pe  
    ON pe.grantee_principal_id = pr.principal_id  
JOIN sys.objects AS o  
    ON pe.major_id = o.object_id  
JOIN sys.schemas AS s  
    ON o.schema_id = s.schema_id;