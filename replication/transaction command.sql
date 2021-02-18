SELECT  DISTINCT publisher_database_id
FROM    sys.servers AS [publishers]
     INNER JOIN distribution.dbo.MSpublications AS [publications] 
          ON publishers.server_id = publications.publisher_id
     INNER JOIN distribution.dbo.MSarticles AS [articles] 
          ON publications.publication_id = articles.publication_id
     INNER JOIN distribution.dbo.MSsubscriptions AS [subscriptions] 
          ON articles.article_id = subscriptions.article_id
               AND articles.publication_id = subscriptions.publication_id
                    AND articles.publisher_db = subscriptions.publisher_db
                    AND articles.publisher_id = subscriptions.publisher_id
     INNER JOIN sys.servers AS [subscribers] 
          ON subscriptions.subscriber_id = subscribers.server_id
WHERE   [publications].publisher_db = 'cassius2017'
          --AND publications.publication = 'cassius2017'
          --AND subscribers.name = 'cassius2017'
          


EXECUTE distribution.dbo.sp_browsereplcmds
    @xact_seqno_start = '0x0000C67000000C77000300000000',
    @xact_seqno_end = '0x0000C67000000C77000300000000',
    @publisher_database_id = 10, 
    @command_id = 1

--DELETE FROM  MSrepl_commands where xact_seqno = 0x0000FD21009F7AFF00B200000000  and command_id = 5 and publisher_database_id = 12

--run on subscriber
--exec sp_setsubscriptionxactseqno @publisher = 'MTR116', @publisher_db = 'cassius_v12', @publication = 'cassius_v12', @xact_seqno = 0x0000C67000000C770003

        