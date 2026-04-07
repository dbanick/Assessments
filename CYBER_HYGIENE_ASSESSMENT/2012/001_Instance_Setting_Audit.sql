
create table #recs (
id int identity,
Audit_Parameter varchar(250),
Determination varchar(250),
Success_Value varchar(250),
Fail_Value varchar(250),
Audit_Desc varchar(250)
)

insert into #recs
select 'EDITION', 'Fail', null, null, 'SQL Edition'

insert into #recs
select 'COMPUTER_NAME', 'Fail', null, null, 'Computer Name'

insert into #recs
select 'DATE_CHECKED', 'Fail', null, null, 'DATE_CHECKED'


insert into #recs
select 'SQL_Version', 'Fail', null, null, 'SQL Version'

insert into #recs
select 'PRODUCT_LEVEL', 'Fail', null, 'RTM', 'Product Level'

insert into #recs
select 'PRODUCT_VERSION',  'Success', '11.0.7001.0',  null, 'SQL Version'

insert into #recs
select 'PRODUCT_VERSION',   'Success','12.0.6329.1', null,  'SQL Version'

insert into #recs
select 'PRODUCT_VERSION', 'Success',  '13.0.5850.14' ,  null, 'SQL Version'

insert into #recs
select 'PRODUCT_VERSION',  'Success', '14.0.3356.20',  null, 'SQL Version'

insert into #recs
select 'PRODUCT_VERSION',  'Success', '15.0.4073.23',  null, 'SQL Version'

insert into #recs
select 'CPU_COUNT',  'Fail', null,  0, 'CPU Count'	

insert into #recs
select 'CHECK_EXPIRATION', 'Success', 0,  null, 'Ensure "CHECK Expiration" Server Configuration Option is set to 0'

insert into #recs
select 'CHECK_POLICY', 'Success', 0,  null, 'Ensure "CHECK Policy" Server Configuration Option is set to 0'

insert into #recs
select 'CLR ENABLED',  'Success',0,  null, 'Ensure "CLR Enabled" Server Configuration Option is set to 0'

insert into #recs
select 'DATABASE MAIL XPS', 'Success', 0	,  null, 'Ensure "DB Mail XP" Server Configuration Option is set to 0'

insert into #recs
select 'REMOTE ACCESS', 'Success', 0	,  null, 'Ensure "Remote Access" Server Configuration Option is set to 0'

insert into #recs
select 'SA_ACCOUNT_DISABLED', 'Success', 1 	,  null, 'Ensure "SA Account Disabed" Server Configuration Option is set to 1'

insert into #recs
select 'SA_ACCOUNT_NAME', 'Fail', null, 'sa', 'Check SA account Name'

insert into #recs
select 'SCAN FOR STARTUP PROCS', 'Success', 0	,  null, 'SCAN FOR STARTUP PROCS'

insert into #recs
select 'WINDOWS_AUTHENTICATION', 'Success', 1 , null,  'Is Windows Auth used'	

insert into #recs
select 'XP_CMDSHELL', 'Success', 0, null, 'Is XP CMDSHELL enabled'



;with CTE_A as (

select @@SERVERName 'SQLInstance', 'DATE_CHECKED' as 'Audit_Parameter',  GETDATE()  'Audit_Value'
UNION

select @@SERVERName 'SQLInstance',
'SQL_Version' 'Audit_Parameter',
case when substring(convert(nvarchar,SERVERPROPERTY('ProductVersion')),0,4) like '9%' then 'SQL SERVER 2005 ' + cast(SERVERPROPERTY('ProductLevel') as varchar(250)) + ' ' + cast(SERVERPROPERTY('Edition') as varchar(250))
	 when substring(convert(nvarchar,SERVERPROPERTY('ProductVersion')),0,4) like '10.0%' then 'SQL SERVER 2008 '  + cast(SERVERPROPERTY('ProductLevel') as varchar(250)) + ' ' + cast(SERVERPROPERTY('Edition') as varchar(250))
	 when substring(convert(nvarchar,SERVERPROPERTY('ProductVersion')),0,4) like '10.5%' then 'SQL SERVER 2008 R2 '  + cast(SERVERPROPERTY('ProductLevel') as varchar(250)) + ' ' + cast(SERVERPROPERTY('Edition') as varchar(250))
	 when substring(convert(nvarchar,SERVERPROPERTY('ProductVersion')),0,4) like '11%' then 'SQL SERVER 2012 '  + cast(SERVERPROPERTY('ProductLevel') as varchar(250)) + ' ' + cast(SERVERPROPERTY('Edition') as varchar(250))
	 when substring(convert(nvarchar,SERVERPROPERTY('ProductVersion')),0,4) like '12%' then 'SQL SERVER 2014 '  + cast(SERVERPROPERTY('ProductLevel') as varchar(250)) + ' ' + cast(SERVERPROPERTY('Edition') as varchar(250))
	 when substring(convert(nvarchar,SERVERPROPERTY('ProductVersion')),0,4) like '13%' then 'SQL SERVER 2016 '  + cast(SERVERPROPERTY('ProductLevel') as varchar(250)) + ' ' + cast(SERVERPROPERTY('Edition') as varchar(250))
	 when substring(convert(nvarchar,SERVERPROPERTY('ProductVersion')),0,4) like '14%' then 'SQL SERVER 2017 '  + cast(SERVERPROPERTY('ProductLevel') as varchar(250)) + ' ' + cast(SERVERPROPERTY('Edition') as varchar(250))
	 when substring(convert(nvarchar,SERVERPROPERTY('ProductVersion')),0,4) like '15%' then 'SQL SERVER 2019 '  + cast(SERVERPROPERTY('ProductLevel') as varchar(250)) + ' ' + cast(SERVERPROPERTY('Edition') as varchar(250))
	 End 'Audit_Value'

UNION
select @@SERVERName 'SQLInstance', 'COMPUTER_NAME' as 'Audit_Parameter',  SERVERPROPERTY('MachineName')  'Audit_Value'
UNION
select @@SERVERName 'SQLInstance', 'PRODUCT_VERSION' as 'Audit_Parameter',  SERVERPROPERTY('ProductVersion') 'Audit_Value'
UNION
select @@SERVERName 'SQLInstance', 'EDITION' as 'Audit_Parameter',  SERVERPROPERTY('EDITION') 'Audit_Value'
UNION
select @@SERVERName 'SQLInstance', 'PRODUCT_LEVEL' as 'Audit_Parameter',  SERVERPROPERTY('ProductLevel')  'Audit_Value'
UNION

select @@SERVERName 'SQLInstance', 'CPU_COUNT' as 'Audit_Parameter',  cpu_count  'Audit_Value' 
FROM sys.dm_os_sys_info

UNION
select @@ServerName 'SQL_Instance', Upper(name) as Audit_Parameter, Value as Audit_Value  
from sys.configurations 

where name in 
(
'CLR Enabled',
 'Database Mail XPs',
 'Remote Access',
 'Scan for Startup Procs',
 'xp_cmdshell'
)

UNION
select @@ServerName 'SQLInstance', 'SA_ACCOUNT_DISABLED', is_disabled  
from sys.server_principals where principal_id = 1

UNION
select @@ServerName 'SQLInstance', 'SA_ACCOUNT_NAME', name as CurrentName 
from sys.server_principals where principal_id = 1

UNION
select @@ServerName 'SQLInstance', 'WINDOWS_AUTHENTICATION'  ,SERVERPROPERTY('IsIntegratedSecurityOnly') as Value 

UNION
select @@servername, 'CHECK_POLICY', Count(1) as Value from sys.sql_logins where is_policy_checked <> 1 

UNION
select @@servername, 'CHECK_EXPIRATION', Count(1) as Value
from sys.sql_logins 
where is_expiration_checked <> 1 and IS_SRVROLEMEMBER('sysadmin',name) = 1

), cte_b as (

select @@ServerName 'SQLInstance',a.Audit_Parameter, a.audit_value, NULL as audit_desc, NULL as Audit_result
from CTE_a a
where not exists (select audit_parameter from #recs where Audit_Parameter = cast(a.audit_parameter as varchar(250)))

UNION ALL

select @@ServerName 'SQLInstance',a.Audit_Parameter, a.audit_value, NULL as audit_desc, NULL as Audit_result
from CTE_a a
join #recs rf on a.Audit_Parameter = rf.audit_parameter and rf.determination IS NULL


UNION ALL

select @@ServerName 'SQLInstance',a.Audit_Parameter, a.audit_value, rp.audit_desc, 
case when cast(a.audit_value as varchar(250)) = rp.Success_Value 
	then 'PASS' 
	ELSE 'FAIL' 
	END as Audit_Result
from cte_a a
join #recs rp on a.Audit_Parameter = rp.audit_parameter and  rp.audit_parameter = 'PRODUCT_VERSION'
and  substring(convert(nvarchar,SERVERPROPERTY('ProductVersion')),0,4) = substring(rp.success_value,0,4)

UNION ALL

select @@ServerName 'SQLInstance',a.Audit_Parameter, a.audit_value, rf.audit_desc,
case when cast(a.audit_value as varchar(250)) = rf.Fail_Value 
	then 'FAIL' 
	ELSE 'PASS' 
	END as Audit_Result
from cte_a a
join #recs rf on a.Audit_Parameter = rf.audit_parameter and rf.determination = 'Fail'

union all
select @@ServerName 'SQLInstance',a.Audit_Parameter, a.audit_value, rs.audit_desc, 
case when cast(a.audit_value as varchar(250)) = rs.Success_Value 
	then 'PASS' 
	ELSE 'FAIL' 
	END as Audit_Result
from cte_a a
join #recs rs on a.Audit_Parameter = rs.audit_parameter and rs.determination = 'Success' and rs.audit_parameter != 'PRODUCT_VERSION'
), cte_p as (
select sqlinstance, audit_parameter, audit_value from cte_b
), cte_r as (
select sqlinstance,  audit_parameter, audit_result from cte_b
), cte_d as (
select sqlinstance,  audit_parameter, audit_desc from cte_b
), cte_final as (


select 1 as ord, * from cte_p

PIVOT(
    MAX(audit_value)
    FOR Audit_Parameter IN (
		[DATE_CHECKED],
		[COMPUTER_NAME],
		[EDITION],
		[SQL_VERSION],
		[PRODUCT_LEVEL],
		[PRODUCT_VERSION],
		[CPU_COUNT],
		[CHECK_EXPIRATION],
		[CHECK_POLICY],
		[CLR ENABLED],
		[DATABASE MAIL XPS],
		[REMOTE ACCESS],
		[SA_ACCOUNT_DISABLED],
		[SA_ACCOUNT_NAME],
		[SCAN FOR STARTUP PROCS],
		[WINDOWS_AUTHENTICATION],
		[XP_CMDSHELL]
	) 
) AS pivot_table 

UNION

select 2 as ord, * from cte_r

PIVOT(
    MAX(audit_result)
    FOR Audit_Parameter IN (
		[DATE_CHECKED],
		[COMPUTER_NAME],
		[EDITION],
		[SQL_VERSION],
		[PRODUCT_LEVEL],
		[PRODUCT_VERSION],
		[CPU_COUNT],
		[CHECK_EXPIRATION],
		[CHECK_POLICY],
		[CLR ENABLED],
		[DATABASE MAIL XPS],
		[REMOTE ACCESS],
		[SA_ACCOUNT_DISABLED],
		[SA_ACCOUNT_NAME],
		[SCAN FOR STARTUP PROCS],
		[WINDOWS_AUTHENTICATION],
		[XP_CMDSHELL]
	) 
) AS pivot_table 

union 


select 3 as ord, * from cte_d

PIVOT(
    MAX(audit_desc)
    FOR Audit_Parameter IN (
		[DATE_CHECKED],
		[COMPUTER_NAME],
		[EDITION],
		[SQL_VERSION],
		[PRODUCT_LEVEL],
		[PRODUCT_VERSION],
		[CPU_COUNT],
		[CHECK_EXPIRATION],
		[CHECK_POLICY],
		[CLR ENABLED],
		[DATABASE MAIL XPS],
		[REMOTE ACCESS],
		[SA_ACCOUNT_DISABLED],
		[SA_ACCOUNT_NAME],
		[SCAN FOR STARTUP PROCS],
		[WINDOWS_AUTHENTICATION],
		[XP_CMDSHELL]
	) 
) AS pivot_table 

)
select * from cte_final order by ord asc
GO
drop table #recs