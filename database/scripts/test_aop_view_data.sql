--
-- ========================================================================
-- Test: Controleer AOP view data voor audit
-- ========================================================================
--

set serveroutput on
set define off
set long 50000
set longchunksize 50000
set linesize 200

define audit_id = 9024

prompt ========================================
prompt AOP View Data voor Audit &audit_id
prompt ========================================
prompt

-- Check of audit bestaat
select  adt.id
,       adt.code
,       cnt.company_name
,       cnt.audit_report_type
from    icca_audits adt
join    icca_clients cnt on cnt.id = adt.cnt_id
where   adt.id = &audit_id;

prompt
prompt AOP Data (JSON):
prompt ========================================

-- Haal AOP data op
select  aop_data
from    icca_aop_report_data_vw
where   adt_id = &audit_id;

prompt
prompt ========================================
prompt Test JSON extractie:
prompt ========================================

-- Test enkele velden
select  json_value(aop_data, '$.data[0].organisatie') as opdrachtgever
,       json_value(aop_data, '$.data[0].audit_straatnaam') as adres
,       json_value(aop_data, '$.data[0].project') as locatiecode
,       json_value(aop_data, '$.data[0].audit_stad') as plaats
,       json_value(aop_data, '$.data[0].datum_controle') as controle_datum
,       json_value(aop_data, '$.data[0].periode') as periode
,       json_value(aop_data, '$.data[0].rapport_nummer') as controlenummer
,       json_value(aop_data, '$.data[0].controle_door') as controleur
from    icca_aop_report_data_vw
where   adt_id = &audit_id;

prompt
prompt ========================================
prompt Test Array Extractie (categories):
prompt ========================================

-- Test categories array
select  json_query(aop_data, '$.data[0].audit_results') as categories_json
from    icca_aop_report_data_vw
where   adt_id = &audit_id;
