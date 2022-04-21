EXEC sys.sp_configure N'show advanced options', N'1'  RECONFIGURE WITH OVERRIDE
EXEC sys.sp_configure N'Database Mail XPs', N'1'
RECONFIGURE
EXEC sys.sp_configure N'show advanced options', N'0'  RECONFIGURE WITH OVERRIDE

EXEC msdb.dbo.sysmail_configure_sp @parameter_name='MaxFileSize', @parameter_value='2147483647', @description='Default maximum file size'

EXEC msdb.dbo.sp_set_sqlagent_properties @email_save_in_sent_folder=1, @databasemail_profile='Job Alerts', @use_databasemail=1
