select  *
from    icca_audits
where   code = '17738'
;

select cat.name as categorie_naam,
      res.counter_elements as tel_element,
      res.approve_limit as goedkeurgrens,
      res.counter_errors as aantal_behaalde_fouten,
      res.score as cijfer,
      case
        when res.is_sufficient = 'Y' then 'Voldoende'
        else 'Onvoldoende'
      end as beoordeling
from icca_adt_results res
join icca_categories cat on cat.id = res.cat_id
where res.adt_id = 18468
order by cat.name
;

select  *
from    icca_incoming_messages
where   json_value(message, '$.audit.Code') = '17738'
order by id desc;

declare
    ln_ige_id   number;
    ln_audit_id number;
begin
    icca_audit_post_api.p_msg_handler( 1648, ln_audit_id );
end;
/

select  *
from    icca_categories
;

select  *
from    icca_error_types
;

select  *
from    icca_audits
where   last_control_date > to_date('19-JAN-2026')
and     cnt_id not in (
  select  id
  from    icca_clients
  where   company_name in ('Test Company 1','Icca-Advies', 'Icca Advies', 'Testbedrijfanjali')
)
and   lower(type) not in ('test')
;


SELECT * --SUM(bytes)/1024/1024 AS MB 
FROM dba_data_files;

SELECT host_name FROM v$instance;

SELECT 
    ROUND(SUM(bytes)/1024/1024/1024, 2) AS total_gb
FROM dba_data_files;

select  *
from    db_growth_log;


CREATE TABLE db_growth_log (
    log_date DATE DEFAULT SYSDATE,
    size_mb NUMBER
);

INSERT INTO db_growth_log (size_mb)
SELECT ROUND(SUM(bytes)/1024/1024, 2)
FROM dba_segments
WHERE tablespace_name = 'ICCA_TS';


SELECT 
    segment_name,
    ROUND(bytes/1024/1024,2) MB
FROM dba_segments
WHERE tablespace_name = 'ICCA_TS'
ORDER BY bytes DESC;

PURGE DBA_RECYCLEBIN;


select  to_address
,       attachment_filename
,       status
,       sent_date
,       created_by sent_by
from    icca_mail_log
where   attachment_filename like '%20136%'
or attachment_filename like '%20479%'
or attachment_filename like '%20478%'
or attachment_filename like '%20432%'
order by 1 desc