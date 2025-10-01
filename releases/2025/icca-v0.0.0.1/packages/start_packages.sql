set define off
set serveroutput on

spool start_packages.log

prompt icca_aop_pdf.pks
@@icca_aop_pdf.pks

prompt icca_audit_get_api.pks
@@icca_audit_get_api.pks

prompt icca_audit_post_api.pks
@@icca_audit_post_api.pks

prompt icca_authentication_ords.pks
@@icca_authentication_ords.pks

prompt icca_authentication.pks
@@icca_authentication.pks

prompt icca_error_handeling.pks
@@icca_error_handeling.pks

prompt icca_incoming_msg.pks
@@icca_incoming_msg.pks

prompt icca_json_util.pks
@@icca_json_util.pks

prompt icca_user_activity_api.pks
@@icca_user_activity_api.pks



spool off

