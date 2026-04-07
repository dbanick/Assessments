/* Database Settings */
/*comparison in PS, modify to just select all these fields in to 1 result set*/

/* Auto Close */
SELECT name, is_auto_close_on FROM sys.databases WHERE is_auto_close_on = 1

/* Auto Shrink */
SELECT name, is_auto_shrink_on FROM sys.databases WHERE is_auto_shrink_on = 1

/* Trustworthy */
SELECT name, is_trustworthy_on FROM sys.databases WHERE is_trustworthy_on = 1 and name <> 'msdb'

/* DBChaining */
SELECT name, is_db_chaining_on FROM sys.databases WHERE is_db_chaining_on = 1 and name not in('master','msdb','tempdb')

/* !Online */
SELECT name, state_desc FROM sys.databases WHERE state_desc <> 'ONLINE'

/* Page Verify */
SELECT name, page_verify_option_desc FROM sys.databases WHERE page_verify_option_desc <> 'CHECKSUM'

/* Compatibility Level */
SELECT name, compatibility_level FROM sys.databases WHERE compatibility_level <> (SELECT compatibility_level from sys.databases where name = 'tempdb')

/* Auto Create Stats */
SELECT name, is_auto_create_stats_on FROM sys.databases WHERE is_auto_create_stats_on <> 1

/* Auto Update Stats */
SELECT name, is_auto_update_stats_on FROM sys.databases WHERE is_auto_update_stats_on <> 1


SELECT [name], [compatibility_level], [is_auto_close_on], [is_auto_shrink_on], [state_desc], [page_verify_option_desc],
[is_auto_create_stats_on], [is_auto_update_stats_on], [is_trustworthy_on], [is_db_chaining_on]
FROM sys.databases
