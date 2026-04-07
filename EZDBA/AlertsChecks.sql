/* Alerts */
CREATE TABLE #Alerts ([ID] INT, [Error] VARCHAR(256), [Enabled] BIT NULL, [Notification] BIT NULL)

INSERT INTO #Alerts
SELECT message_id, name, [enabled], [has_notification] FROM msdb..sysalerts
where message_id IN (823,824,825,829,832)

INSERT into #Alerts
SELECT severity, name, [enabled], [has_notification] FROM msdb..sysalerts
where severity IN (19,20,21,22,23,24,25)

IF NOT EXISTS (SELECT message_id FROM msdb..sysalerts WHERE message_id = 823) INSERT INTO #Alerts VALUES (823, 'Operating System Error',NULL,NULL)
IF NOT EXISTS (SELECT message_id FROM msdb..sysalerts WHERE message_id = 824) INSERT INTO #Alerts VALUES (824, 'I/O Error',NULL,NULL)
IF NOT EXISTS (SELECT message_id FROM msdb..sysalerts WHERE message_id = 825) INSERT INTO #Alerts VALUES (825, 'File Error',NULL,NULL)
IF NOT EXISTS (SELECT message_id FROM msdb..sysalerts WHERE message_id = 829) INSERT INTO #Alerts VALUES (829, 'Restore Pending',NULL,NULL)
IF NOT EXISTS (SELECT message_id FROM msdb..sysalerts WHERE message_id = 832) INSERT INTO #Alerts VALUES (832, 'Constant Page Changed',NULL,NULL)
IF NOT EXISTS (SELECT severity FROM msdb..sysalerts WHERE severity = 19) INSERT INTO #Alerts VALUES (19, 'Severity - Error In Resources',NULL,NULL)
IF NOT EXISTS (SELECT severity FROM msdb..sysalerts WHERE severity = 20) INSERT INTO #Alerts VALUES (20, 'Severity - Error In Current Process',NULL,NULL)
IF NOT EXISTS (SELECT severity FROM msdb..sysalerts WHERE severity = 21) INSERT INTO #Alerts VALUES (21, 'Severity - Fatal Error In DB Processes',NULL,NULL)
IF NOT EXISTS (SELECT severity FROM msdb..sysalerts WHERE severity = 22) INSERT INTO #Alerts VALUES (22, 'Severity - Fatal Error Table Integrity Suspect',NULL,NULL)
IF NOT EXISTS (SELECT severity FROM msdb..sysalerts WHERE severity = 23) INSERT INTO #Alerts VALUES (23, 'Severity - Fatal Error DB Integrity Suspect',NULL,NULL)
IF NOT EXISTS (SELECT severity FROM msdb..sysalerts WHERE severity = 24) INSERT INTO #Alerts VALUES (24, 'Severity - Fatal Error Hardware',NULL,NULL)
IF NOT EXISTS (SELECT severity FROM msdb..sysalerts WHERE severity = 25) INSERT INTO #Alerts VALUES (25, 'Severity - Fatal System Error',NULL,NULL)

SELECT * FROM #Alerts
DROP TABLE #Alerts
