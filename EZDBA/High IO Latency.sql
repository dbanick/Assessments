/* High Latency */
SELECT
	@@SERVERNAME AS [Server Name],
    DB_NAME(fs.database_id) AS [Database Name] ,
    mf.physical_name AS [Physical Name],
    CAST(io_stall_read_ms / ( 1.0 + num_of_reads ) AS NUMERIC(10, 1)) AS [Avg Read Stall (ms)] ,
    CAST(io_stall_write_ms / ( 1.0 + num_of_writes ) AS NUMERIC(10, 1)) AS [Avg Write Stall (ms)] ,
    CAST(( io_stall_read_ms + io_stall_write_ms ) / ( 1.0 + num_of_reads + num_of_writes ) AS NUMERIC(10,1)) AS [Avg IO Stall (ms)],
    CURRENT_TIMESTAMP AS [Collection Time] 
FROM
    sys.dm_io_virtual_file_stats(NULL, NULL) AS fs
    INNER JOIN sys.master_files AS mf ON fs.database_id = mf.database_id
                                         AND fs.[file_id] = mf.[file_id]
ORDER BY [Avg IO Stall (ms)] DESC
OPTION (RECOMPILE);
