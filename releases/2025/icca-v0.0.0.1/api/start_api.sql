set define off

spool start_api.log


prompt ords_config.sql
@@ords_config.sql

prompt oauth.sql
@@oauth.sql

prompt api.sql
@@api.sql

prompt auth.sql
@@auth.sql

prompt login.sql
@@login.sql

prompt getAudits.sql
@@getAudits.sql

prompt getUserActivity.sql
@@getUserActivity.sql

prompt postAudits.sql
@@postAudits.sql

prompt postImage.sql
@@postImage.sql


spool off
