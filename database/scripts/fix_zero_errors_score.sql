-----------------------------------------------------------------------------------------
-- Fix: Score moet 10 zijn wanneer counter_errors = 0
-- Datum: 15-FEB-2026
-- Beschrijving: Door een bug in p_calculate_audit_results werd bij 0 fouten
--               de score niet op 10 gezet, maar afhankelijk van de approve_limit.
--               Dit script corrigeert alle bestaande rijen in icca_adt_results
--               waar counter_errors = 0 en score != 10.
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- Stap 1: Analyseer welke audits getroffen zijn (ALLEEN LEZEN)
-----------------------------------------------------------------------------------------
-- Alle resultaten waar counter_errors = 0 maar score != 10
select  ars.id              as result_id
,       ars.adt_id
,       adt.code            as audit_code
,       ars.cat_id
,       cat.name            as categorie
,       ars.counter_elements
,       ars.approve_limit
,       ars.counter_errors
,       ars.score           as huidige_score
,       10                  as nieuwe_score
,       ars.is_sufficient   as huidig_is_sufficient
,       'Y'                 as nieuw_is_sufficient
,       cnt.company_name
,       cln.name            as location_name
,       adt.audit_date
from    icca_adt_results        ars
join    icca_audits             adt on adt.id = ars.adt_id
join    icca_clients            cnt on cnt.id = adt.cnt_id
join    icca_client_locations   cln on cln.id = adt.cln_id
left join icca_categories       cat on cat.id = ars.cat_id
where   ars.counter_errors = 0
and     ars.score != 10
order by adt.audit_date desc, ars.adt_id, ars.cat_id
;

-----------------------------------------------------------------------------------------
-- Stap 2: Fix specifiek audit code 20119
-----------------------------------------------------------------------------------------
update  icca_adt_results
set     score           = 10
,       is_sufficient   = 'Y'
where   counter_errors  = 0
and     score          != 10
and     adt_id in (
            select  id
            from    icca_audits
            where   code = '20119'
        )
;

-- Controleer resultaat voor audit 20119
select  ars.*
from    icca_adt_results    ars
join    icca_audits         adt on adt.id = ars.adt_id
where   adt.code = '20119'
order by ars.id desc
;

-----------------------------------------------------------------------------------------
-- Stap 3: Fix ALLE getroffen audits in productie
-- VOER DIT PAS UIT NA CONTROLE VAN STAP 1
-----------------------------------------------------------------------------------------
update  icca_adt_results
set     score           = 10
,       is_sufficient   = 'Y'
where   counter_errors  = 0
and     score          != 10
;

-- Toon aantal bijgewerkte rijen
-- select sql%rowcount as aantal_bijgewerkt from dual;

commit;
