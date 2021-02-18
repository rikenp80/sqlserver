--on 201:

use UnifiedJobs
go

EXEC sp_dropsubscription 
  @publication = 'P2P-UnifiedJobs', 
  @article = 'SSPXRef',
  @subscriber = 'TJGSQLT301';
GO


EXEC sp_droparticle 
  @publication = 'P2P-UnifiedJobs', 
  @article = 'SSPXRef',
  @force_invalidate_snapshot = 1;
GO



--on 301:

use UnifiedJobs
go

EXEC sp_dropsubscription 
  @publication = 'P2P-UnifiedJobs', 
  @article = 'SSPXRef',
  @subscriber = 'TJGSQLT201';
GO


EXEC sp_droparticle 
  @publication = 'P2P-UnifiedJobs', 
  @article = 'SSPXRef',
  @force_invalidate_snapshot = 1;
GO


delete from SSPXRef



