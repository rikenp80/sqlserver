drop table #Replication

SELECT DISTINCT publisher.name 'publisher', p.publisher_db, p.publication, subscriber.name 'subscriber', s.subscriber_db, s.subscription_type
INTO #Replication
FROM	sys.servers AS publisher
			INNER JOIN distribution.dbo.MSpublications p ON publisher.server_id = p.publisher_id
			INNER JOIN distribution.dbo.MSsubscriptions s ON p.publication_id = s.publication_id
			INNER JOIN sys.servers AS subscriber ON subscriber.server_id = s.subscriber_id
ORDER BY publisher_db, subscriber.name

ALTER TABLE #Replication ADD ID INT IDENTITY(1,1)



DECLARE @ID INT = 1,
		@publisher VARCHAR(50),
		@publisher_db VARCHAR(50),
		@publication VARCHAR(50),
		@subscriber VARCHAR(50),
		@subscriber_db VARCHAR(50),
		@subscription_type INT



WHILE @ID <= (SELECT MAX(ID) FROM #Replication)
BEGIN
	SELECT	@publisher = publisher,
			@publisher_db = publisher_db,
			@publication = publication,
			@subscriber = subscriber,
			@subscriber_db = subscriber_db,
			@subscription_type = subscription_type
	FROM #Replication WHERE ID = @ID
	
	SELECT @publisher_db 'publisher_db', @publication 'publication', @subscriber 'subscriber', @subscriber_db 'subscriber_db'
	
	EXECUTE distribution.dbo.sp_replmonitorsubscriptionpendingcmds 
		@publisher = @publisher,
		@publisher_db = @publisher_db,
		@publication = @publication,
		@subscriber = @subscriber,
		@subscriber_db = @subscriber_db,
		@subscription_type = @subscription_type
	
	SET @ID += 1
END

