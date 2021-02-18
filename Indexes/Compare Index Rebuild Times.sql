USE DBA_Logs
GO
SELECT * FROM Log_Index_Rebuild lir ORDER BY RunDate DESC
SELECT * FROM Log_Index_Rebuild lir WHERE DatabaseName = 'LoungeGateway' ORDER BY RunDate DESC, TableName, IndexName
SELECT * FROM Log_Index_Rebuild lir WHERE IndexName = 'card_tokenisation_number_idx1' ORDER BY RunDate DESC



DECLARE @AfterChange TABLE (DatabaseName VARCHAR(200), IndexName VARCHAR(200), Avg_BeforeRebuildFragment INT, Avg_RebuildDurationSecs INT)
DECLARE @BeforeChange TABLE (DatabaseName VARCHAR(200), IndexName VARCHAR(200), Avg_BeforeRebuildFragment INT, Avg_RebuildDurationSecs INT)

INSERT INTO @AfterChange
SELECT DatabaseName, IndexName, AVG(BeforeRebuildFragment), AVG(RebuildDurationSecs)
FROM Log_Index_Rebuild 
WHERE RunDate > '2013-09-03 10:00'
GROUP BY DatabaseName, IndexName


INSERT INTO @BeforeChange
SELECT DatabaseName, IndexName, AVG(BeforeRebuildFragment), AVG(RebuildDurationSecs)
FROM Log_Index_Rebuild 
WHERE RunDate BETWEEN '2013-01-01' AND '2013-09-03 10:00'
GROUP BY DatabaseName, IndexName


SELECT a.IndexName, b.Avg_BeforeRebuildFragment 'Avg_BeforeChange_Fragment', b.Avg_RebuildDurationSecs 'Avg_BeforeChange_Duration', a.Avg_BeforeRebuildFragment 'Avg_AfterChange_Fragment', a.Avg_RebuildDurationSecs 'Avg_AfterChange_Duration'
FROM @AfterChange a INNER JOIN @BeforeChange b ON a.IndexName = b.IndexName AND a.DatabaseName = b.DatabaseName
ORDER BY a.Avg_BeforeRebuildFragment