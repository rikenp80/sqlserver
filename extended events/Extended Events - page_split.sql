DROP EVENT SESSION EE_Page_Split ON SERVER
GO
CREATE EVENT SESSION EE_Page_Split ON SERVER
ADD EVENT sqlserver.page_split
    (ACTION (sqlserver.database_id, sqlserver.sql_text) 
    WHERE sqlserver.database_id > 4)
ADD TARGET package0.asynchronous_file_target
    (SET FILENAME='E:\ExtendedEventLogs\EE_Page_Split.xel',
    metadatafile='E:\ExtendedEventLogs\EE_Page_Split.xem')
GO
ALTER EVENT SESSION EE_Page_Split ON SERVER STATE = START
GO



DROP TABLE PageSplits
GO
CREATE TABLE PageSplits
	(
	PageSplitID	INT IDENTITY(1,1) NOT NULL,
	xml_data	XML,
	[Date]		DATETIME2(3),
	[File_ID]	SMALLINT,
	Page_ID		INT,
	Database_ID	TINYINT,
	sql_text	NVARCHAR(MAX)
	)
GO	
ALTER TABLE PageSplits ADD CONSTRAINT PK_PageSplits PRIMARY KEY NONCLUSTERED (PageSplitID) WITH FILLFACTOR = 100
GO
CREATE CLUSTERED INDEX IDX_PageSplits_Date ON PageSplits([Date]) WITH FILLFACTOR = 95
GO



INSERT INTO PageSplits (xml_data, [Date], [File_ID], Page_ID, Database_ID, sql_text)
SELECT	xml_data,
		xml_data.value('(/event[@name=''page_split'']/@timestamp)[1]','datetime'),
		xml_data.value('(/event/data[@name=''file_id'']/value)[1]','int'),
		xml_data.value('(/event/data[@name=''page_id'']/value)[1]','int'),
		xml_data.value('(/event/action[@name=''database_id'']/value)[1]','int'),
		xml_data.value('(/event/action[@name=''sql_text'']/value)[1]','varchar(max)')
FROM
	(
	SELECT object_name 'event', CONVERT(xml, event_data) 'xml_data'
	FROM sys.fn_xe_file_target_read_file ('E:\ExtendedEventLogs\EE_Page_Split*.xel', 'E:\ExtendedEventLogs\EE_Page_Split*.xem', NULL, NULL)
	) AS a
	
	
SELECT *
FROM PageSplits
--WHERE [Date] >= CAST(GETDATE() as DATE)
ORDER BY [Date] desc