--temp table to store full list of txid to delete
DROP TABLE IF EXISTS #txid_all_listed
CREATE TABLE #txid_all_listed (TXID INT)

--variables for managin while loop
DECLARE @CurrentID INT = 0
DECLARE @MaxID INT
SELECT @MaxID=MAX(ID) FROM #DuplicateTransactionTable

--SELECT COUNT(*) FROM #DuplicateTransactionTable
PRINT (@MaxID)


--loop through each row in #DuplicateTransactionTable, split txids list into table and ignore the MAX txid when inserting into #txid_all_listed
WHILE @CurrentID <> @MaxID
BEGIN
	
	SET @CurrentID = @CurrentID + 1
	

	INSERT INTO #txid_all_listed
	SELECT value
	FROM #DuplicateTransactionTable  
		CROSS APPLY STRING_SPLIT(txids, ';')
	WHERE ID = @CurrentID

	
END
GO


SELECT count(*) FROM #txid_all_listed