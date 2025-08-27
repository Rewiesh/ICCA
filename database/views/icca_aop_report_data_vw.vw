create or replace view icca_aop_report_data_vw
as
with w_pfr as(
    select  fom.adt_id
    ,       pfr.id
    ,       case when pfr.is_auditor = 'Y' then pfr.first_name ||' '|| pfr.last_name  else null end as controle_door
    ,       row_number() over (partition by fom.adt_id order by pfr.id) rn
    from    icca_adt_forms  fom
    join    icca_performers pfr on fom.pfr_id = pfr.id
)
, w_adt as(
    select
            trim(to_char(adt.audit_date, 'FMDD Mon YYYY', 'NLS_DATE_LANGUAGE = DUTCH'))             as datum_controle_volledig
        ,   adt.id                                                                                  as adt_id
        ,   cnt.company_name                                                                        as organisatie
        ,   clt.contact_person                                                                      as ter_attentie_van
        ,   clt.name                                                                                as project
        ,   adt.code                                                                                as rapport_nummer
        ,   to_char(adt.audit_date, 'DD-MM-YYYY')                                                   as datum_controle
        ,   to_char(adt.audit_date, 'HH24:MI')                                                      as tijdstip_controle
        ,   pfr.controle_door                                                                           as controle_door
        ,   nvl(null, 'n.v.t.')                                                                     as aanwezig_leverancier --> double check
        ,   clt.country                                                                             as audit_land
        ,   clt.city                                                                                as audit_stad
        ,   clt.street_name                                                                         as audit_straatnaam
    from    icca_audits adt
    join    icca_clients            cnt on adt.cnt_id = cnt.id
    join    icca_client_locations   clt on adt.cln_id = clt.id
    -- * join on adt_forms may produce multiple rows, so fetch first row as all performers should be the same anyways
    join    w_pfr                   pfr on (pfr.adt_id = adt.id and rn = 1)
    where   adt.audit_completed = 'Y'
) --select * from w_adt;
,
w_column_chart
as(
    select  ars.adt_id
    ,       json_object(
                 'title'      value ''
             ,   'xAxis'   value  json_array(
                     json_object(
                          'title'   value 'XAxis'
                      ,    'data'    value json_arrayagg(
                              json_object(
                                      'value' value cat.name
                              )
                          )
                    )
                )
             ,   'yAxis'   value  json_array(
                     json_object(
                          'title'   value 'Ytitle'
                        , 'series'  value json_array(
                                json_object(
                                      'name' value 'Cijfer'
                                  ,    'data'    value json_arrayagg(
                                            json_object(
                                                    'value' value ars.score
                                            )
                                        )
                                )
                            ,
                                json_object(
                                      'name' value 'Goedkeurgrens'
                                  ,    'data'    value json_arrayagg(
                                            json_object(
                                                    'value' value 6
                                            )
                                        )
                                )
                          )
                      )
                )
            )
             as chart_spec
    from    icca_adt_results    ars
    join    icca_categories     cat on ars.cat_id = cat.id
    group by ars.adt_id
)
select  json_array(
            json_object(
                    'filename' value 'rapport'
                ,   'data'     value
                            json_array(
                                json_object(
                                  ------------------------------ Algemeen -------------------------------------
                                      'datum_controle_volledig'   value adt.datum_controle_volledig
                                  ------------------------------ Pagina 1 -------------------------------------
                                  ,   'audit_id'                  value adt.adt_id
                                  ,   'organisatie'               value adt.organisatie
                                  ,   'ter_attentie_van'          value adt.ter_attentie_van
                                  ,   'project'                   value adt.project
                                  ,   'rapport_nummer'            value adt.rapport_nummer
                                  ,   'datum_controle'            value adt.datum_controle
                                  ,   'tijdstip_controle'         value adt.tijdstip_controle
                                  ,   'controle_door'             value adt.controle_door
                                  ,   'aanwezig_leverancier'      value adt.aanwezig_leverancier--> double check
                                  ------------------------------ Pagina 2 -------------------------------------
                                  ,   'audit_land'                value adt.audit_land
                                  ,   'audit_stad'                value adt.audit_stad
                                  ,   'audit_straatnaam'          value adt.audit_straatnaam
                                ------------------------------ Chart Data -------------------------------------
                                    ,   'columnLineChart'         value json_array(cch.chart_spec)

                                )
                            )
                )
        )as aop_data
from w_adt          adt
join w_column_chart cch on adt.adt_id = cch.adt_id
where  adt.adt_id = 7642
;


