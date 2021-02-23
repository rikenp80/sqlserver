SET NOCOUNT ON

CREATE TABLE #alter_table (exec_command VARCHAR(1000))
INSERT INTO #alter_table
SELECT	'ALTER TABLE [' + c.name 
		+ '] ALTER COLUMN [' + a.name 
		+ '] ' 
		+ REPLACE(b.name, 'n', '') + '(' + CASE WHEN a.[length] = -1 THEN 'MAX' ELSE CAST(a.[length]/2 AS VARCHAR(50)) END + ') '
		+ CASE WHEN a.isnullable = 1 THEN 'NULL' ELSE 'NOT NULL' END
FROM sys.syscolumns a
		INNER JOIN systypes b ON a.xtype = b.xtype	
		INNER JOIN sys.tables c ON a.id = c.[object_id]
WHERE b.name = 'nvarchar'
ORDER BY c.name, a.name


DECLARE @Current_Record VARCHAR(500)

SELECT @Current_Record = MIN(exec_command) FROM #alter_table

WHILE @Current_Record IS NOT NULL
BEGIN

	PRINT @Current_Record
	EXEC (@Current_Record)

	DELETE FROM #alter_table WHERE exec_command = @Current_Record
	SELECT @Current_Record = MIN(exec_command) FROM #alter_table

END

GO