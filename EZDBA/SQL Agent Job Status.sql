/* SQL Agent Jobs */
create table #jobtemp (JobName varchar(512), LastRunStatus varchar(255))
insert into #jobtemp
SELECT j.name AS [JobName]
	,CASE jh.run_status
		WHEN 0 THEN 'Fail'
		WHEN 1 THEN 'Succeeded'
		WHEN 2 THEN 'Retry'
		WHEN 3 THEN 'Cancel'
		WHEN 4 THEN 'In Progress'
		ELSE 'Status Unknown'
	 END AS [LastRunStatus]
FROM (
	msdb.dbo.sysjobactivity ja LEFT JOIN msdb.dbo.sysjobhistory jh WITH (NOLOCK) ON ja.job_history_id = jh.instance_id
	)
JOIN msdb.dbo.sysjobs_view j WITH (NOLOCK) ON ja.job_id = j.job_id
WHERE ja.session_id = (
		SELECT MAX(session_id)
		FROM msdb.dbo.sysjobactivity
		)
		and jh.run_status in (0,2,3)
ORDER BY [JobName]
OPTION (RECOMPILE)
if (select count(*) from #jobtemp) = 0
insert into #jobtemp VALUES ('Pass','Pass')

SELECT * FROM #jobtemp

drop table #jobtemp