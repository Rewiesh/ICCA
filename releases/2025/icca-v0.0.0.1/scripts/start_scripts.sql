set define off

spool start_scripts.log

-- possible errors in install script but it should be fine
prompt logger_install.sql
@@logger_install.sql

prompt aop_db_pkg.sql
@@aop_db_pkg.sql

spool off
