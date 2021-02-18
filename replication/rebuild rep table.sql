--on 201:

use UnifiedJobs
go

EXEC sp_dropsubscription 
  @publication = 'P2P-UnifiedJobs', 
  @article = 'SSPXRef',
  @subscriber = '';
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
  @subscriber = '';
GO


EXEC sp_droparticle 
  @publication = 'P2P-UnifiedJobs', 
  @article = 'SSPXRef',
  @force_invalidate_snapshot = 1;
GO


delete from SSPXRef



