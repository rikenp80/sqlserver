select	b.spid 'blocked spid',
		b.blocked 'blocking_spid',
		b.[program_name] 'blocked_program_name',
		a.[program_name] 'blocking_program_name',
		b.waitresource 'blocked_waitresource',
		a.waitresource 'blocking_waitresource',
		b.hostname 'blocked_host',
		a.hostname 'blocking_host',
		b.[sql_handle] 'blocked_sql_handle',
		a.[sql_handle] 'blocking_sql_handle',
		b.*, a.*
from sysprocesses a inner join sysprocesses b on b.blocked = a.spid 
where b.blocked <> 0
order by b.blocked