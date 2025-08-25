create or replace view icca_aop_report_data_vw
as
with w_adt as(
    select
            trim(to_char(adt.audit_date, 'FMDD Mon YYYY', 'NLS_DATE_LANGUAGE = DUTCH'))             as datum_controle_volledig
        ,   adt.id                                                                                  as audit_id
        ,   cnt.company_name                                                                        as organisatie
        ,   clt.contact_person                                                                      as ter_attentie_van
        ,   clt.name                                                                                as project
        ,   adt.code                                                                                as rapport_nummer
        ,   to_char(adt.audit_date, 'DD-MM-YYYY')                                                   as datum_controle
        ,   to_char(adt.audit_date, 'HH24:MI')                                                      as tijdstip_controle
        ,   case when prf.is_auditor = 'Y' then prf.first_name ||' '|| prf.last_name  else null end as controle_door
        ,   nvl(null, 'n.v.t.')                                                                     as aanwezig_leverancier --> double check
        ,   clt.country                                                                             as audit_land
        ,   clt.city                                                                                as audit_stad
        ,   clt.street_name                                                                         as audit_straatnaam
    from    icca_audits adt
    join    icca_clients          cnt on adt.cnt_id = cnt.id
    join    icca_client_locations clt on adt.cln_id = clt.id
    join    icca_adt_forms        fom on fom.adt_id = adt.id
    join    icca_performers       prf on fom.pfr_id = prf.id
    where   adt.id = 7724
    and     adt.audit_completed = 'Y'
    fetch first row only
    -- * join on adt_forms may produce multiple rows, so fetch first row as all performers will be the same anyways
)
select  json_arrayagg(
            json_object(
                    'filename' value 'rapport'
                ,   'data'     value
                        (
                            select
                            json_arrayagg(
                                json_object(
                                         ------------------------------ Algemeen -------------------------------------
                                        'datum_controle_volledig'   value adt.datum_controle_volledig
                                        ------------------------------ Pagina 1 -------------------------------------
                                ,       'audit_id'                  value adt.audit_id
                                ,       'organisatie'               value adt.organisatie
                                ,       'ter_attentie_van'          value adt.ter_attentie_van
                                ,       'project'                   value adt.project
                                ,       'rapport_nummer'            value adt.rapport_nummer
                                ,       'datum_controle'            value adt.datum_controle
                                ,       'tijdstip_controle'         value adt.tijdstip_controle
                                ,       'controle_door'             value adt.controle_door
                                ,       'aanwezig_leverancier'      value adt.aanwezig_leverancier--> double check
                                        ------------------------------ Pagina 2 -------------------------------------
                                ,       'audit_land'                value adt.audit_land
                                ,       'audit_stad'                value adt.audit_stad
                                ,       'audit_straatnaam'          value adt.audit_straatnaam
                                )
                            )
                        )
                )
        )as aop_data
from w_adt adt ;