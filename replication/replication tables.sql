SELECT o.name 'table_name', p.name 'publication_name', *
FROM sysarticles a inner join sys.objects o on a.objid = o.object_id
		inner join syspublications p on a.pubid = p.pubid
order by o.name

select * from sysarticles