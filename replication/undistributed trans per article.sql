--declare @max_xact_seqno varbinary
select xact_seqno, *
    from dbo.MSdistribution_history
    where agent_id = 17
        and timestamp = (
						select max(timestamp)
						from dbo.MSdistribution_history
						where agent_id = 17
						)


select *  from MSrepl_commands where xact_seqno > 0x0002499900020AD80150000000000000

select c.article_id, a.article, count(*)
from MSrepl_commands c inner join MSarticles a on c.article_id = a.article_id
where xact_seqno > 0x0002499900020AD80150000000000000
group by c.article_id, a.article
order by count(*) desc