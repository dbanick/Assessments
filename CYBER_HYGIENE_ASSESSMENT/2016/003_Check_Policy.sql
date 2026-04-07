
SELECT SQLLoginName = sp.name, 
PasswordPolicyEnforced = CAST(sl.is_policy_checked AS BIT) FROM sys.server_principals sp
JOIN sys.sql_logins AS sl ON sl.principal_id = sp.principal_id WHERE sp.type_desc = 'SQL_LOGIN';    