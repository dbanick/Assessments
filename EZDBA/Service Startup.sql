/*Automatic Startup Check */
SELECT servicename AS [Service Name], startup_type_desc AS [Startup Type],
is_clustered AS [Is Clustered]
FROM sys.dm_server_services
where servicename like 'SQL Server%'