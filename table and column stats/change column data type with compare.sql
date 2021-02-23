USE Infostore_CXP151_Prod
GO

--DECLARE @BackupFilePath VARCHAR(500) = 'G:\Infostore_CXP151_Prod_20160825_154700_CopyOnly.BAK'

--ALTER DATABASE Infostore_CXP151_Prod SET SINGLE_USER WITH ROLLBACK IMMEDIATE

--RESTORE DATABASE Infostore_CXP151_Prod
--FROM DISK = @BackupFilePath
--WITH RECOVERY, REPLACE, STATS = 10,
--MOVE 'Infostore_CXP151_Prod' TO 'D:\DATA\Infostore_CXP151_Prod.mdf',
--MOVE 'Infostore_CXP151_Prod_log' TO 'F:\LOGS\Infostore_CXP151_Prod_log.LDF'
--GO



create table #Infostore_CXP151_Prod (table_name varchar(500), column_name varchar(500), data_type varchar(500), data_length int)
insert into #Infostore_CXP151_Prod
select	c.name,
		a.name,
		b.name,
		a.length
FROM Infostore_CXP151_Prod.sys.syscolumns a
		INNER JOIN Infostore_CXP151_Prod.sys.types b ON a.xusertype = b.user_type_id
		INNER JOIN Infostore_CXP151_Prod.sys.tables c ON a.id = c.[object_id]
where is_ms_shipped = 0
		


create table #Infostore_CXP14_Prod (table_name varchar(500), column_name varchar(500), data_type varchar(500), data_length int, nullable bit)
insert into #Infostore_CXP14_Prod	
select	c.name 'table_name',
		a.name 'column_name',
		b.name,
		a.length,
		a.isnullable
FROM Infostore_CXP14_Prod.sys.syscolumns a
		INNER JOIN Infostore_CXP14_Prod.sys.types b ON a.xusertype = b.user_type_id
		INNER JOIN Infostore_CXP14_Prod.sys.tables c ON a.id = c.[object_id]
where is_ms_shipped = 0


select a.table_name, a.column_name, a.data_type '14_datatype', b.data_type '15_1_datatype', a.data_length '14_datalength', b.data_length '15_1_datalength',
		'ALTER TABLE [' + a.table_name
		+ '] ALTER COLUMN [' + a.column_name
		+ '] ' 
		+ a.data_type
		+ '(' + CASE WHEN a.data_type = 'nvarchar'  THEN CAST(a.data_length/2 AS VARCHAR(50)) ELSE CAST(a.data_length AS VARCHAR(50)) END
		+ ') '
		+ case when a.nullable = 1 then 'NULL' else 'NOT NULL' END as 'AlterScript'
into #alter_columns
from #Infostore_CXP14_Prod a inner join #Infostore_CXP151_Prod b
		on a.table_name = b.table_name
		and a.column_name = b.column_name
where a.data_type <> b.data_type
order by a.table_name, a.column_name




select * from #alter_columns

/*
select * from sys.indexes
select * from sys.index_columns
select * from sys.columns
select * from sys.tables
*/

select distinct
case when i.is_primary_key = 0
	then 'DROP INDEX [' + i.name + '] ON [' + t.name + ']'
	else 'ALTER TABLE [' + t.name + '] DROP CONSTRAINT [' + i.name + ']'
end 'DROP'

--case when i.is_primary_key = 0
--	then 'CREATE ' + i.type_desc collate SQL_Latin1_General_CP1_CI_AS + ' INDEX [' + i.name + '] ON [' + t.name + ']('
--	else 'ALTER TABLE [' + t.name + '] ADD CONSTRAINT [' + i.name + '] PRIMARY KEY ' + i.type_desc collate SQL_Latin1_General_CP1_CI_AS + '('
--end 'CREATE'
--,t.name
from sys.indexes i
		inner join sys.index_columns ic on i.object_id = ic.object_id and i.index_id = ic.index_id
		inner join sys.columns c on ic.object_id = c.object_id and ic.column_id = c.column_id
		inner join sys.tables t on c.object_id = t.object_id
		inner join #alter_columns a on t.name = a.table_name and c.name = a.column_name




drop table #Infostore_CXP151_Prod
drop table #Infostore_CXP14_Prod
drop table #alter_columns
