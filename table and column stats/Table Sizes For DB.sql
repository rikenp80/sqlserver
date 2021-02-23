CREATE TABLE #TableSizes
	(
	name			VARCHAR(500),
	rows			INT,
	reserved_mb		VARCHAR(500),
	data_mb			VARCHAR(500),
	index_size_mb	VARCHAR(500),
	unused_mb		VARCHAR(500)
	)
	
CREATE TABLE #TableSizesINT
	(
	name			VARCHAR(500),
	rows			INT,
	reserved_mb		INT,
	data_mb			INT,
	index_size_mb	INT,
	unused_mb		INT
	)
		

DECLARE @CurrentTable VARCHAR(1000)
DECLARE @SQL VARCHAR(1000)

SELECT @CurrentTable = min(s.name + '.' + t.name) from sys.tables t left join sys.schemas s on t.schema_id = s.schema_id

WHILE @CurrentTable IS NOT NULL
BEGIN

	SET @SQL = 'INSERT INTO #TableSizes EXEC sp_spaceused [' + @CurrentTable + ']'
	
	PRINT @SQL
	EXEC (@SQL)

	SELECT @CurrentTable = min(s.name + '.' + t.name) from sys.tables t left join sys.schemas s on t.schema_id = s.schema_id WHERE s.name + '.' + t.name > @CurrentTable

END

UPDATE #TableSizes SET reserved_mb = REPLACE(reserved_mb, ' KB', '')/1024
UPDATE #TableSizes SET data_mb = REPLACE(data_mb, ' KB', '')/1024
UPDATE #TableSizes SET index_size_mb = REPLACE(index_size_mb, ' KB', '')/1024
UPDATE #TableSizes SET unused_mb = REPLACE(unused_mb, ' KB', '')/1024

INSERT INTO #TableSizesINT SELECT * FROM #TableSizes

SELECT * FROM #TableSizesINT ORDER BY data_mb DESC

DROP TABLE #TableSizes
DROP TABLE #TableSizesINT
