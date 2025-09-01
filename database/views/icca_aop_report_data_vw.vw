create or replace view icca_aop_report_data_vw
as
with
------------------------------ * Data CTE's *  -------------------------------------
  w_fom as(
    select  /*+ MATERIALIZE*/
            fom.id          id
    ,       fom.adt_id      adt_id
    ,       fom.area_number area_number
    ,       fom.flr_id      flr_id
    ,       fom.cat_id      cat_id
    ,       fom.ara_id      ara_id
    ,       fom.pfr_id      pfr_id
    from    icca_adt_forms fom
  )
, w_pfr as(
    select  fom.adt_id  adt_id
    ,       pfr.id      pfr_id
    ,       case when pfr.is_auditor = 'Y' then pfr.first_name ||' '|| pfr.last_name  else null end as controle_door
    ,       row_number() over (partition by fom.adt_id order by pfr.id) rn
    from    w_fom           fom
    join    icca_performers pfr on fom.pfr_id = pfr.id
)
, w_adt as(
    select
            trim(to_char(adt.audit_date, 'FMDD Mon YYYY', 'NLS_DATE_LANGUAGE = DUTCH'))             as datum_controle_volledig
        ,   adt.id                                                                                  as adt_id
        ,   cnt.company_name                                                                        as organisatie
        ,   cln.contact_person                                                                      as ter_attentie_van
        ,   cln.name                                                                                as project
        ,   adt.code                                                                                as rapport_nummer
        ,   adt.audit_date                                                                          as datum_controle
        ,   to_char(adt.audit_date, 'HH24:MI')                                                      as tijdstip_controle
        ,   pfr.controle_door                                                                       as controle_door
        ,   nvl(null, 'n.v.t.')                                                                     as aanwezig_leverancier --> double check
        ,   cln.country                                                                             as audit_land
        ,   cln.city                                                                                as audit_stad
        ,   cln.street_name                                                                         as audit_straatnaam
        ,   cln.id                                                                                  as cln_id
    from    icca_audits adt
    join    icca_clients            cnt on adt.cnt_id = cnt.id
    join    icca_client_locations   cln on adt.cln_id = cln.id
    -- * join on adt_forms may produce multiple rows, so fetch first row as all performers should be the same anyways
    join    w_pfr                   pfr on (pfr.adt_id = adt.id and rn = 1)
    where   adt.audit_completed = 'Y'
) --select * from w_adt;
, w_adt_results as(
  select  /*+ MATERIALIZE*/
          ars.adt_id            adt_id
  ,       ars.score             score
  ,       ars.approve_limit     approve_limit
  ,       ars.counter_elements  counter_elements
  ,       ars.counter_errors    counter_errors
  ,       cat.name              cat_name
  from    icca_adt_results      ars
  join    icca_categories       cat on ars.cat_id = cat.id
)
, w_frs as (
    select  frr_agg.agg_error_count agg_error_count
    ,       frr_agg.adt_id          adt_id
    ,       ete.name                ete_name
    ,       max(frr_agg.agg_error_count) over (partition by frr_agg.adt_id) as max_errors
    from
        (
            select      frr.ete_id
            ,           fom.adt_id
            ,           sum(frr.error_count) as agg_error_count
            from        w_fom               fom
            join        icca_fom_errors     frr on fom.id = frr.fom_id
            group by    frr.ete_id
            ,           fom.adt_id
        ) frr_agg
    join    icca_error_types ete on frr_agg.ete_id = ete.id
)
, w_adt_related_scores as (
    select  adt_main.adt_id             main_adt_id
    ,       adt_related.adt_id          related_adt_id
    ,       adt_related.datum_controle  related_adt_date
    ,       ars.score                   related_score
    ,       ars.approve_limit           related_approve_limit
    from    w_adt           adt_main
    join    w_adt           adt_related on ( adt_main.cln_id = adt_related.cln_id and adt_main.adt_id < adt_related.adt_id)
    join    w_adt_results   ars         on ars.adt_id = adt_related.adt_id
) --select * from w_adt_related_scores where main_adt_id = 279;
, w_fom_detail as (
    select      fom.adt_id                                                                      adt_id
    ,           flr.name || ' - ' || trim(ara.abbreviation) || '.' ||  fom.area_number          area_number
    ,           cat.name                                                                        cat_name
    ,           epe.name                                                                        epe_name
    ,           ete.name                                                                        ete_name
    ,           frs.log_book_remark                                                             log_book_remark
    ,           case when log_book_image_id is not null then
                    row_number() over (partition by fom.adt_id order by log_book_image_id) end  picture_number
    from        icca_adt_forms fom
    join        icca_floors         flr on fom.flr_id            = flr.id
    join        icca_areas          ara on fom.ara_id            = ara.id
    join        icca_categories     cat on fom.cat_id            = cat.id
    join        icca_fom_errors     frs on frs.fom_id            = fom.id
    join        icca_elementtypes   epe on frs.epe_id            = epe.id
    join        icca_error_types    ete on frs.ete_id            = ete.id
    left join   icca_documents      doc on frs.log_book_image_id = doc.id
)
------------------------------ * Chart CTE's *  -------------------------------------
, w_column_chart
as(
    select  ars.adt_id
    ,       json_object(
                 'title'      value 'Chart Title'
             ,   'xAxis'   value  json_array(
                     json_object(
                          'title'   value 'xAxis'
                      ,    'data'    value json_arrayagg(
                              json_object(
                                      'value' value ars.cat_name
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
                                                    'value' value ars.approve_limit
                                            )
                                        )
                                )
                          )
                      )
                )
            )
             as chart_spec
    from    w_adt_results ars
    group by adt_id
)
,
w_stock_chart
as
(
    select  adt_id
    ,       json_object(
                        'title'   value 'Test'
                    ,   'xAxis'   value  json_array(
                            json_object(
                                'title'   value 'XAxis'
                            ,    'data'    value json_arrayagg(
                                    json_object(
                                            'value' value ete_name || chr(10)  /*||chr(9) */ || frs.agg_error_count
                                    )
                                )
                            )
                        )
                    ,   'yAxis'   value  json_array(
                            json_object(
                                'title'   value 'Ytitle'
                                , 'series'  value json_array(
                                        json_object(
                                            'name' value 'open',
                                            'data' value json_arrayagg(frs.agg_error_count)
                                        )
                                        ,
                                        json_object(
                                            'name' value 'high',
                                            'data' value json_arrayagg(frs.max_errors)
                                        )
                                        ,
                                        json_object(
                                            'name' value 'low',
                                            'data' value json_arrayagg(0)
                                        )
                                        ,
                                        json_object(
                                            'name' value 'close',
                                            'data' value json_arrayagg(frs.agg_error_count - 1)
                                        )
                                )
                            )
                    )
                    )
                as chart_spec
        from    w_frs frs
        group by adt_id
)
,
w_timeline_chart as (
    select  main_adt_id
    -- ,       related_adt_id
    ,       json_object(
                 'title'      value 'Chart Title'
             ,   'xAxis'   value  json_array(
                     json_object(
                          'title'   value 'xAxis'
                      ,    'data'    value json_arrayagg(
                              json_object(
                                      'value' value rsc.related_adt_date
                              )
                          )
                    )
                )
             ,   'yAxis'   value  json_array(
                     json_object(
                          'title'   value 'Ytitle'
                        , 'series'  value json_array(
                                json_object(
                                      'name' value 'Series1'
                                  ,    'data'    value json_arrayagg(
                                            json_object(
                                                    'value' value rsc.related_score
                                            )
                                        )
                                )
                            ,
                                json_object(
                                      'name' value 'Series2'
                                  ,    'data'    value json_arrayagg(
                                            json_object(
                                                    'value' value rsc.related_approve_limit
                                            )
                                        )
                                )
                          )
                      )
                )
            ) as chart_spec
    from    w_adt_related_scores rsc
    group by main_adt_id
)
------------------------------ * Table CTE's *  -------------------------------------
,
w_audit_results_tbl
as
(
    select  adt_id
    ,       json_arrayagg(
                    json_object(
                            'categorie'     value   ars.cat_name
                        ,   'tel_elementen' value   ars.counter_elements
                        ,   'goedkeurgrens' value   ars.approve_limit
                        ,   'aantal_fouten' value   ars.counter_errors
                        ,   'beoordeling'   value   case when ars.counter_errors < ars.approve_limit then 'Y' else 'N' end --* Y for voldoende N for Onvoldoende
                    )
            ) as tbl_spec
    from    w_adt_results ars
    group by adt_id
)
, w_room_level_comments_tbl
as
(
    select  adt_id      adt_id
    ,       json_arrayagg(
                    json_object(
                            'ruimte_nr' value area_number
                        ,   'categorie' value cat_name
                        ,   'element'   value epe_name
                        ,   'vuilsoort' value ete_name
                        ,   'opmerking' value log_book_remark
                        ,   'foto_nr'   value picture_number
                        )
    order by picture_number asc ) as tbl_spec
    from        w_fom_detail
    group by adt_id


)
select  json_array(
            json_object(
                    'filename' value 'rapport'
                ,   'data'     value
                            json_array(
                                json_object(
                                  ------------------------------ * Algemeen *  -------------------------------------
                                      'datum_controle_volledig'   value adt.datum_controle_volledig
                                  ------------------------------ * Pagina 1 * -------------------------------------
                                  ,   'audit_id'                  value adt.adt_id
                                  ,   'organisatie'               value adt.organisatie
                                  ,   'ter_attentie_van'          value adt.ter_attentie_van
                                  ,   'project'                   value adt.project
                                  ,   'rapport_nummer'            value adt.rapport_nummer
                                  ,   'datum_controle'            value to_char(adt.datum_controle, 'dd-mm-yyyy')
                                  ,   'tijdstip_controle'         value adt.tijdstip_controle
                                  ,   'controle_door'             value adt.controle_door
                                  ,   'aanwezig_leverancier'      value adt.aanwezig_leverancier--> double check
                                  ------------------------------ * Pagina 2 * -------------------------------------
                                  ,   'audit_land'                value adt.audit_land
                                  ,   'audit_stad'                value adt.audit_stad
                                  ,   'audit_straatnaam'          value adt.audit_straatnaam
                                ------------------------------ * Chart Data *  -------------------------------------
                                  ,   'colChart'                  value json_array(cch.chart_spec)
                                  ,   'stockChart'                value json_array(sch.chart_spec)
                                --   ,   'timelineChart'             value json_array(tch.chart_spec)
                                ------------------------------ * Table Data *  -------------------------------------
                                  ,   'audit_results'                value ars_tbl.tbl_spec
                                  ,   'ruimteniveau_opmerkingen'     value rlc_tbl.tbl_spec
                                )
                            )
                )
         )as aop_data
,       adt.adt_id adt_id
from w_adt              adt
join w_column_chart     cch on adt.adt_id = cch.adt_id
join w_stock_chart      sch on adt.adt_id = sch.adt_id
-- join w_timeline_chart   tch on adt.adt_id = tch.main_adt_id
join    w_audit_results_tbl         ars_tbl on ars_tbl.adt_id = adt.adt_id
join    w_room_level_comments_tbl   rlc_tbl on rlc_tbl.adt_id = adt.adt_id
-- cross join w_stock_chart sch
-- where  adt.adt_id = 279
;

