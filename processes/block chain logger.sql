create table #blocking
(
blocked_spid smallint,
blocking_spid smallint,
blocked_program_name nchar(256),
blocking_program_name nchar(256),
blocked_waitresource nchar(512),
blocking_waitresource nchar(512),
blocked_host nchar(256),
blocking_host nchar(256),
blocked_sql_handle nvarchar(max),
blocking_sql_handle nvarchar(max)
)

while 1=1
begin
	insert into #blocking
	select	b.spid 'blocked spid',
			b.blocked 'blocking_spid',
			b.[program_name] 'blocked_program_name',
			a.[program_name] 'blocking_program_name',
			b.waitresource 'blocked_waitresource',
			a.waitresource 'blocking_waitresource',
			b.hostname 'blocked_host',
			a.hostname 'blocking_host',
			blocked.[text] 'blocked_sql_handle',
			blocking.[text] 'blocking_sql_handle'
	from sysprocesses a
		INNER join sysprocesses b on b.blocked = a.spid 
		CROSS APPLY sys.dm_exec_sql_text(b.[sql_handle]) blocked
		CROSS APPLY sys.dm_exec_sql_text(a.[sql_handle]) blocking
	where b.blocked <> 0

	WAITFOR DELAY '00:00:05';
end

/*
select * from #blocking
drop table #blocking
*/


