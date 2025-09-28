set define off

spool start_scripts.log

-- possible errors in install script but it should be fine
prompt logger_install.sql
@@logger_install.sql

spool off
