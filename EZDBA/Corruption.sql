/* Database Corruption */
create table #corruptioncheck ([Result] varchar(100), [DatabaseName] sysname NULL, [FileID] int NULL, [PageID] bigint NULL, [EventType] int NULL)
declare @count int

insert into #corruptioncheck
SELECT 'Corruption' AS [Result], DB_NAME(database_id) AS [DatabaseName], file_id AS [FileID], page_id AS [PageID], event_type AS [EventType]
FROM msdb.dbo.suspect_pages
WHERE event_type IN (1,2,3) 
ORDER BY [DatabaseName] OPTION (RECOMPILE)

set @count = (select count(*) from #corruptioncheck)
if @count = 0
begin
insert into #corruptioncheck VALUES ('No Corruption',NULL,NULL,NULL,NULL)
END

select * from #corruptioncheck

drop table #corruptioncheck