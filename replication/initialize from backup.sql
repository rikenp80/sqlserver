
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