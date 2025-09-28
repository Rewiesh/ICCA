set define off
set serveroutput on

spool start_package_bodies.log

prompt icca_error_handeling.pkb
@@icca_error_handeling.pkb

prompt icca_aop_pdf.pkb
@@icca_aop_pdf.pkb

prompt icca_incoming_msg.pkb
@@icca_incoming_msg.pkb

prompt icca_json_util.pkb
@@icca_json_util.pkb

prompt icca_audit_get_api.pkb
@@icca_audit_get_api.pkb

prompt icca_audit_post_api.pkb
@@icca_audit_post_api.pkb

prompt icca_authentication.pkb
@@icca_authentication.pkb

prompt icca_authentication_ords.pkb
@@icca_authentication_ords.pkb

prompt icca_user_activity_api.pkb
@@icca_user_activity_api.pkb

spool off

