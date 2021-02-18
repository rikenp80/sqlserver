use Infostore_CXP13_Prod_P
go

exec sp_helppublication 'Infostore_CXP13_Prod_P'
 
EXEC sp_changepublication 
  @publication = 'Infostore_CXP13_Prod_P', 
  @property = 'allow_initialize_from_backup', 
  @value = true

  
EXEC sp_addsubscription
@publication = 'Infostore_CXP13_Prod_P',
@subscriber = '889794-CHTR-DBC',
@destination_db = 'Infostore_CXP13_Prod_P',
@sync_type = 'initialize with backup',
@backupdevicetype ='disk',
@backupdevicename = 'E:\Backup\Infostore_CXP13_Prod_P\Infostore_CXP13_Prod_P_Full_2018_10_08_233600.bak'
GO

EXEC sp_addpushsubscription_agent
@publication = 'Infostore_CXP13_Prod_P',
@subscriber = '889794-CHTR-DBC',
@subscriber_db='Infostore_CXP13_Prod_P',
@subscriber_security_mode = 0,
@subscriber_login='replman',
@subscriber_password='2013!R3plM@n'
GO





EXEC sp_addsubscription
@publication = 'eWFM_P_WFMCC',
@subscriber = 'VM0PWEWFMXD0002',
@destination_db = 'EWFM',
@sync_type = 'initialize with backup',
@backupdevicetype ='disk',
@backupdevicename = 'F:\Backups\eWFM_P_WFMCC_Full_20180219_104500.BAK'
GO

EXEC sp_addpushsubscription_agent
@publication = 'eWFM_P_WFMCC',
@subscriber = 'VM0PWEWFMXD0002',
@subscriber_db='EWFM',
@subscriber_security_mode = 0,
@subscriber_login='sa',
@subscriber_password=''
GO