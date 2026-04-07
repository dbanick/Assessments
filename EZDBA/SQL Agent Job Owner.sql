/* SQL Agent Jobs Not Owned by sa */
SELECT j.name AS [JobName]
	,SUSER_SNAME(j.owner_sid) AS [Job Owner]
FROM  msdb.dbo.sysjobs_view j WITH (NOLOCK)
WHERE  SUSER_SNAME(j.owner_sid) <> 'sa'
ORDER BY [JobName]
OPTION (RECOMPILE);