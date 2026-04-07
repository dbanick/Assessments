/* Database Settings */
SELECT [name], [compatibility_level], [is_auto_close_on], [is_auto_shrink_on], [state_desc], [page_verify_option_desc],
[is_auto_create_stats_on], [is_auto_update_stats_on], [is_trustworthy_on], [is_db_chaining_on]
FROM sys.databases