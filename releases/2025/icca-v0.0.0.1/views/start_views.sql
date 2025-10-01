set define off

spool start_views.log

prompt icca_aop_report_data_vw.vw
@@icca_aop_report_data_vw.vw

prompt icca_cities_vw.vw
@@icca_cities_vw.vw

prompt icca_provinces_vw.vw
@@icca_provinces_vw.vw


spool off
