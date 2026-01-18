/*
 * OPTIMALISATIE AUDIT SELECTIE QUERY
 * ==================================
 * Deze script voegt indexen toe om de performance van de audit query te verbeteren.
 * 
 * PROBLEEM ANALYSE:
 * 1. Filter performance: De query filtert op 'audit_completed = Y', maar hier is geen index voor.
 * 2. Join performance: De joins via cnt_id, cln_id en bch_id hebben geen FK indexen (behalve PKs).
 * 3. Subquery performance: De correlatie 'fom.adt_id = adt.id' in de SELECT-lijst wordt voor ELKE rij uitgevoerd.
 *    Zonder index op icca_adt_forms(adt_id) resulteert dit in een full table scan per audit.
 *
 * OPLOSSING:
 * Onderstaande indexen aanmaken.
 */

-- 1. CRITICAAL: Index voor de subquery (count forms)
-- Zonder deze index doet de database een Full Table Scan op icca_adt_forms voor elke audit.
CREATE INDEX icca_fom_adt_id_idx ON icca_adt_forms(adt_id);

-- 2. Index op de filter kolom van de hoofd query
-- Om snel audits te vinden waar audit_completed = 'Y'
CREATE INDEX icca_adt_completed_idx ON icca_audits(audit_completed);

-- 3. Indexen voor Foreign Keys (Verbeteren join performance)

-- Join: icca_audits -> icca_clients
CREATE INDEX icca_adt_cnt_id_idx ON icca_audits(cnt_id);

-- Join: icca_audits -> icca_client_locations
CREATE INDEX icca_adt_cln_id_idx ON icca_audits(cln_id);

-- Join: icca_clients -> icca_branches
CREATE INDEX icca_cnt_bch_id_idx ON icca_clients(bch_id);

-- Optioneel: Join icca_client_locations -> icca_clients
CREATE INDEX icca_cln_cnt_id_idx ON icca_client_locations(cnt_id);

/*
 * AANBEVOLEN QUERY AANPASSING
 * ===========================
 * De originele query evalueert de conditie 'adt.audit_completed = Y' opnieuw in de CASE statements.
 * Dit is overbodig omdat de WHERE clause dit al filtert.
 *
 * Verder is het 'count(1)' in een scalar subquery meestal efficiënt genoeg MET de juiste index (zie 1).
 */

/*
select  adt.id                  as adt_id
,       adt.code                as audit_code
,       adt.audit_date          as audit_date
,       adt.last_control_date   as audit_last_controle_date
,       adt.active              as audit_active_ind
,       bch.name                as branch_name
,       cnt.company_name        as company_name
,       clt.name                as location_name
,       adt.type                as audit_type
,       adt.activate            as audit_activiate_ind
,       adt.audit_completed     as audit_completed_ind
,       case 
            -- 'adt.audit_completed = Y' check verwijderd (is redundant door WHERE clause)
            when (select count(1) from icca_adt_forms fom where fom.adt_id = adt.id) > 0
                then '<i class="fa fa-forms"></i>' 
            else '<span class="disabled-icon" title="Audit nog niet voltooid."><i class="fa fa-forms"></i></span>'
        end audit_formulieren  
,       '<span class="link-icon"><i class="fa fa-bar-chart"></i></span>'               as audit_report
,       case 
            when (select count(1) from icca_adt_forms fom where fom.adt_id = adt.id) > 0
                then '<i class="fa fa-bar-chart"></i>' 
            else '<span class="disabled-icon" title="Audit nog niet voltooid."><i class="fa fa-forms"></i></span>'
        end print
,       nvl2(cnt.audit_report_type, cnt.audit_report_type || '_TEMPLATE.docx', 'ICCA_TEMPLATE.docx') as report_type
,       adt.code || '.' || cnt.company_name || '.' || clt.name  as report_name          
from    icca_audits           adt
join    icca_clients          cnt on adt.cnt_id = cnt.id
join    icca_client_locations clt on adt.cln_id = clt.id
join    icca_branches         bch on cnt.bch_id = bch.id
where   adt.audit_completed = 'Y'
*/
