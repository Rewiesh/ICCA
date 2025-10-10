set define off
create or replace view icca_aop_report_data_vw
as
with
------------------------------ * Data CTE's *  -------------------------------------
  w_fom as(
    select  /*+ MATERIALIZE*/
            fom.id          id
    ,       fom.adt_id      adt_id
    ,       fom.flr_id      flr_id
    ,       fom.cat_id      cat_id
    ,       fom.ara_id      ara_id
    ,       fom.pfr_id      pfr_id
    ,       fom.remark      rmk
    ,       flr.name || ' - ' || trim(ara.abbreviation) || '.' ||  fom.area_number          area_number
    ,       cat.name                                                                        cat_name
    ,       fom.error_count                                                                 error_count
    from    icca_adt_forms fom
    join    icca_floors         flr on fom.flr_id = flr.id
    join    icca_areas          ara on fom.ara_id = ara.id
    join    icca_categories     cat on fom.cat_id = cat.id
)
, w_pfr as(
    select  fom.adt_id  adt_id
    ,       pfr.id      pfr_id
    ,       case when pfr.is_auditor = 'Y' then pfr.first_name ||' '|| pfr.last_name  else null end as controle_door
    ,       row_number() over (partition by fom.adt_id order by pfr.id) rn
    from    w_fom           fom
    join    icca_performers pfr on fom.pfr_id = pfr.id
)
, w_apt as(
    select      adt_id adt_id
    ,           listagg(name, ', ') within group(order by apt.id) as apt_names
    from        icca_adt_present_clients apt
    group by    adt_id
)
, w_adt as(
    select
            trim(to_char(adt.last_control_date, 'FMDD Mon YYYY', 'NLS_DATE_LANGUAGE = DUTCH'))      as datum_controle_volledig
        ,   adt.id                                                                                  as adt_id
        ,   cnt.company_name                                                                        as organisatie
        ,   cln.contact_person                                                                      as ter_attentie_van
        ,   cln.name                                                                                as project
        ,   adt.code                                                                                as rapport_nummer
        ,   adt.last_control_date                                                                   as datum_controle
        ,   to_char(adt.last_control_date, 'HH24:MI')                                               as tijdstip_controle
        ,   pfr.controle_door                                                                       as controle_door
        ,   nvl(apt_names, 'n.v.t.')                                                                as aanwezig_leverancier
        ,   cln.country                                                                             as audit_land
        ,   cln.city                                                                                as audit_stad
        ,   cln.street_name                                                                         as audit_straatnaam
        ,   cln.id                                                                                  as cln_id
        ,   cnt.id                                                                                  as cnt_id
        ,   nvl2(doc.file_url, 'https://icca-dashboard.maxapex.net/' || doc.file_url, doc.file_url) as doc_file_url --* Maybe replace with apex_mail.get_instance_url?
        ,   adt.code || '.' || cnt.company_name || '.' || cln.name                                  as report_name
        ,   cnt.audit_report_type                                                                   as audit_report_type
    from    icca_audits adt
    join    icca_clients            cnt on adt.cnt_id = cnt.id
    join    icca_client_locations   cln on adt.cln_id = cln.id
    left join    icca_documents          doc on cnt.logo_id = doc.id
    -- * join on adt_forms may produce multiple rows, so fetch first row as all performers should be the same anyways
    join        w_pfr                   pfr on (pfr.adt_id = adt.id and rn = 1)
    left join   w_apt                   apt on apt.adt_id = adt.id
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
, w_frs_actuals as (
    select  frr_agg.agg_error_count agg_error_count
    ,       frr_agg.adt_id          adt_id
    ,       ete_id                  ete_id
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
    join icca_error_types ete on frr_agg.ete_id = ete.id
)
, w_frs_complete as (
    select  all_combinations.adt_id
    ,       all_combinations.ete_id
    ,       all_combinations.ete_name
    ,       nvl(frs.agg_error_count, 0) as agg_error_count
    ,       (select max(max_errors) from w_frs_actuals where adt_id = all_combinations.adt_id) as max_errors
    from    (
        select  distinct adt_id
        ,       ete.id ete_id
        ,       ete.name ete_name
        from    w_fom
        cross join icca_error_types ete
    ) all_combinations
    left join w_frs_actuals frs on (frs.adt_id = all_combinations.adt_id and frs.ete_id = all_combinations.ete_id)
)
, w_frs_classes as (
    select  adt_id
    ,       case
                when regexp_like(lower(ete_name),
                        '^(niet geleegd|niet aangevuld|spinrag|niet gehecht vuil( licht stof)?|niet gehecht vuil methode)$')
                    then 'Dagelijkse'
                when regexp_like(lower(ete_name),
                        '^(aanslag|dicht stof|gehecht vuil( vlek( vingertast)?| methode)?|gehecht vuil vlek,? vingertast)$')
                    then 'Cumulatief'
                else 'Diverse'
            end as class
    ,       agg_error_count
    from    w_frs_complete frs
)
, w_frs_classes_agg as (
    select  adt_id
    ,       class
    ,       case class
                when 'Dagelijkse' then 0
                when 'Cumulatief' then 1
                else 2
            end as sort_order
    ,       sum(agg_error_count) as agg_error_count
    ,       round(100 * sum(agg_error_count) / nullif(sum(sum(agg_error_count)) over (partition by adt_id),0), 1)  as pct
    from w_frs_classes
    group by adt_id, class
)
-- select * from w_frs_complete where adt_id = 7722;
/*
    * Get related audits and current audit
    * If > 6 records keep only top 3 detail records PER audit
    * Limit to max 6 records in total, otherwise timeline chart looks messy
*/
, w_adt_related_scores as (
    select  adt_main.adt_id             main_adt_id
    ,       adt_related.adt_id          related_adt_id
    ,       adt_related.datum_controle  related_adt_date
    ,       adt_related.rapport_nummer  related_adt_code
    ,       ars.score                   related_score
    ,       ars.approve_limit           related_approve_limit
    ,       row_number() over (
                partition by adt_related.adt_id
                order by adt_related.datum_controle desc
            ) as rn_related
        ,   count(*) over (partition by adt_main.adt_id) as total_rows
    from    w_adt           adt_main
    join    w_adt           adt_related on ( adt_main.cln_id = adt_related.cln_id and adt_main.datum_controle >= adt_related.datum_controle ) --* Ensure main adt_id is also included
    join    w_adt_results   ars         on ars.adt_id = adt_related.adt_id
)
,
w_adt_related_scores_limited as(
    select  ars.*
    ,       row_number() over (partition by main_adt_id order by related_adt_date desc) as rn_global
    from    w_adt_related_scores ars
    where ((rn_related <= 3 and total_rows > 6)
    or    (total_rows <= 6))
)
,
w_adt_related_scores_final as (
    select  ars.main_adt_id
    ,       ars.related_adt_id
    ,       ars.related_adt_date
    ,       ars.related_adt_code
    ,       ars.related_score
    ,       ars.related_approve_limit
    ,       avg(ars.related_score) over (partition by main_adt_id order by related_adt_date asc rows between 1 preceding and current row) as rolling_avg
    from    w_adt_related_scores_limited ars
    where   rn_global <= 6
) --select * from w_adt_related_scores_final where main_adt_id = 2809; --2809
, w_fom_all as (
    select
          adt_id
        , area_number
        , error_count
        , cat_name
        , epe_name
        , ete_name
        , log_book_remark
        , frs_id
        , doc_id
        , doc_type
        , case when doc_id is not null then
          dense_rank() over (
             partition by adt_id
             order by
             case when doc_id is not null then 0 else 1 end, frs_id
            --  case when doc_id is not null then frs_id end
          )
         end
         as grp_rank
    from (
        -- (log book rows)
        select  fom.adt_id          as adt_id
        ,       fom.area_number     as area_number
        ,       fom.error_count     as error_count
        ,       cat_name            as cat_name
        ,       epe.name            as epe_name
        ,       ete.name            as ete_name
        ,       frs.log_book_remark as log_book_remark
        ,       frs.id              as frs_id
        ,       doc_log_book.id     as doc_id
        ,       'LOG'               as doc_type
        from    w_fom fom
        join    icca_fom_errors     frs on frs.fom_id = fom.id
        join    icca_elementtypes   epe on frs.epe_id = epe.id
        join    icca_error_types    ete on frs.ete_id = ete.id
        --* Doc Log Book
        left join icca_documents doc_log_book  on frs.log_book_image_id = doc_log_book.id
        union all
        -- (technical aspects rows)
        select  fom.adt_id          as adt_id
        ,       fom.area_number     as area_number
        ,       fom.error_count     as error_count
        ,       cat_name            as cat_name
        ,       epe.name            as epe_name
        ,       ete.name            as ete_name
        ,       frs.log_book_remark as log_book_remark
        ,       frs.id              as frs_id
        ,       doc_tech_aspects.id as doc_id
        ,       'TECH'              as doc_type
        from    w_fom fom
        join    icca_fom_errors     frs on frs.fom_id = fom.id
        join    icca_elementtypes   epe on frs.epe_id = epe.id
        join    icca_error_types    ete on frs.ete_id = ete.id
        --* Doc Tech Aspects
        left join icca_documents doc_tech_aspects on frs.technical_aspects_image_id = doc_tech_aspects.id
    ) docs
)
-- select * from w_fom_all
-- where adt_id = 7722;
, w_fom_doc_cnt as(
    select  count(grp_rank) max_cnt
    ,       adt_id
    ,       grp_rank from w_fom_all
    group by adt_id, grp_rank
)
-- select * from w_fom_doc_cnt where adt_id = 7722;
,
w_fom_doc_grouped as (
    select  adt_id
    ,       grp_rank
    ,       max_cnt
    from w_fom_doc_cnt
    where max_cnt = (select max(max_cnt) from w_fom_doc_cnt)
)
-- select * from w_fom_doc_grouped
-- where adt_id = 7722;
, w_fom_doc_ordered as (
    select fom.*,
           row_number() over (
               partition by adt_id
               order by case when grp_rank in (select grp_rank
                                              from w_fom_doc_grouped
                                              where adt_id = fom.adt_id)
                             then 0 else 1 end,
                        grp_rank,
                        frs_id,
                        case when doc_type = 'LOG' then 0 else 1 end
           ) as new_picture_number
    from w_fom_all fom
)
, w_fom_detail as (
    select adt_id
    ,      area_number
    ,      error_count
    ,      cat_name
    ,      epe_name
    ,      ete_name
    ,      log_book_remark
    ,      listagg(case when doc_id is not null then new_picture_number end, ' + ')
              within group(order by new_picture_number asc) as picture_number
    ,      listagg(case when doc_id is not null then doc_id end, ',')
             within group(order by new_picture_number asc) as doc_ids
    from w_fom_doc_ordered
    group by adt_id, area_number, error_count, cat_name, epe_name, ete_name, log_book_remark
    order by min(new_picture_number)
) --select * from w_fom_detail where adt_id = 2;
, w_kpi as (
    select      adt.id              adt_id
    ,           ket.name            ket_name
    ,           case ant.element_value
                    when 'O' then 'Onvoldoende'
                    when 'V' then 'Voldoende'
                    when 'G' then 'Goed'
                    when 'N' then 'N.v.t.'
                end                 ant_element_value
    ,           ant.element_comment ant_element_comment
    from        icca_audits             adt
    join        icca_ket_clients        kcn on adt.cnt_id = kcn.cnt_id
    join        icca_kpi_elementen      ket on kcn.ket_id = ket.id
    left join   icca_adt_kpi_elements   ant on (ant.kcn_id = kcn.id and ant.ket_id = kcn.ket_id and adt.id = ant.adt_id)
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
    select  frs.adt_id
    ,       json_object(
                 'title'      value 'Chart Title'
             ,   'xAxis'   value  json_array(
                     json_object(
                          'title'   value 'xAxis'
                      ,   'data'    value json_array('{"value" : 1}, {"value" : 3}, {"value" : 5}, {"value" : 7}, {"value" : 9} , {"value" : 11}, {"value" : 13}, {"value" : 15}, {"value" : 17}' format json)
                    )
                )
             ,   'yAxis'   value  json_array(
                     json_object(
                          'title'   value 'Ytitle'
                        , 'series'  value json_array(
                                json_object(
                                      'name' value 'Cijfer'
                                  ,   'data'    value json_arrayagg(
                                            json_object(
                                                    'value' value frs.agg_error_count
                                            )
                                            -- * Hardcoded ???
											order by case ete_name
												when 'niet gehecht vuil licht stof' then 0
												when 'niet gehecht vuil methode' 	then 1
												when 'aanslag' 						then 2
												when 'dicht stof' 					then 3
												when 'gehecht vuil methode' 		then 4
												when 'gehecht vuil vlek vingertast' then 5
												when 'niet aangevuld' 				then 6
												when 'niet geleegd' 				then 7
												when 'spinrag' 						then 8
                                            end
                                        )
                                )
                          )
                      )
                )
            )
             as chart_spec
        from    w_frs_complete frs
        group by adt_id
)
,
w_timeline_chart as (
    select  main_adt_id
    ,       json_object(
                 'title'      value 'Chart Title'
             ,   'xAxis'   value  json_array(
                     json_object(
                          'title'   value 'xAxis'
                      ,    'data'    value json_arrayagg(
                              json_object(
                                      'value' value to_char(rsc.related_adt_date, 'dd/mm/yy') || chr(13) || '    ' || rsc.related_adt_code
                              )
                           order by rsc.related_adt_date asc
                           returning clob )
                     returning clob )
                 returning clob )
             ,   'yAxis'   value  json_array(
                     json_object(
                          'title'   value 'Ytitle'
                        , 'series'  value json_array(
                                json_object(
                                      'name' value 'Cijfer'
                                  ,    'data'    value json_arrayagg(
                                            json_object(
                                                    'value' value rsc.related_score
                                            )
                                         order by rsc.related_adt_date asc
                                         returning clob )
                                 returning clob )
                            ,
                                json_object(
                                      'name' value 'Goedkeurgrens'
                                  ,    'data'    value json_arrayagg(
                                            json_object(
                                                    'value' value rsc.related_approve_limit
                                            )
                                         order by rsc.related_adt_date asc
                                         returning clob )
                                 returning clob )
                            ,
                                json_object(
                                      'name' value '2 per. Zw. Gem.'
                                  ,    'data'    value json_arrayagg(
                                            json_object(
                                                    'value' value rsc.rolling_avg
                                            )
                                         order by rsc.related_adt_date asc
                                         returning clob )
                                 returning clob )
                           returning clob )
                       returning clob )
                returning clob )
            returning clob) as chart_spec
    from    w_adt_related_scores_final rsc
    group by main_adt_id
)
,
w_donut_chart as (
    select  adt_id
    ,       json_object(
                 'title'      value 'Chart Title'
             ,   'xAxis'   value  json_array(
                     json_object(
                          'title'   value 'xAxis'
                      ,   'data'    value json_array('{"value" : "Dagelijkse"}, {"value" : "Cumulatief"}, {"value" : "Diverse"}' format json)
                    )
                )
             ,   'yAxis'   value  json_array(
                     json_object(
                          'title'   value 'Ytitle'
                        , 'series'  value json_array(
                                json_object(
                                      'name' value 'Cijfer'
                                  ,   'data'    value json_transform(
                                            json_arrayagg(
                                                json_object(
                                                        'value' value pct
                                                )
                                            order by sort_order asc
                                            )
                                         , set '$append_data' = '[{"value":0}, {"value":100}]' format json
                                         , append '$' = path '$append_data[*]'
                                        )
                        --   ,   'data'    value json_array('{"value" :10}, {"value" : 65}, {"value" : 25},{"value" : 100}' format json)

                                )
                          )
                      )
                )
            )
             as chart_spec
    , json_arrayagg(
                to_char(pct, 'FM999990.0') || '%'
                order by sort_order asc
    ) as donut_pct
    from    w_frs_classes_agg
    group by adt_id
)
-- select * from w_frs_classes_agg where adt_id = 7724;
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
    ,       listagg(doc_ids, ',') within group(order by picture_number) as doc_ids
    ,       json_arrayagg(
                    json_object(
                            'ruimte_nr'     value area_number
                        ,   'categorie'     value cat_name
                        ,   'element'       value epe_name
                        ,   'vuilsoort'     value ete_name
                        ,   'opmerking'     value log_book_remark
                        ,   'aantal_fouten' value error_count
                        ,   'foto_nr'       value picture_number
                        returning clob )
                order by picture_number asc
                returning clob
            ) as tbl_spec
    from        w_fom_detail
    group by adt_id
) --select * from w_room_level_comments_tbl where adt_id = 2;
, w_general_comments_tbl
as
(
    select  adt_id      adt_id
    ,       json_arrayagg(
                    json_object(
                            'ruimte_nr' value fom.area_number
                        ,   'opmerking' value fom.rmk
                    )
                returning clob
            ) as tbl_spec
    from        w_fom fom
    where    fom.rmk is not null
    group by adt_id
)
, w_other_and_hygienic_comments_tbl
as
(
    select  adt_id      adt_id
    ,       json_arrayagg(
                    json_object(
                            'algemeen'      value kpi.ket_name
                        ,   'status'        value kpi.ant_element_value
                        ,   'opmerking'     value kpi.ant_element_comment
                    )
                returning clob
            ) as tbl_spec
    from        w_kpi kpi
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
                                  ,   'aanwezig_leverancier'      value adt.aanwezig_leverancier
                                  ,   'client_logo'               value adt.doc_file_url
                                  ,   'client_logo_max_width'              value 225
                                  ,   'client_logo_max_height'             value 150
                                  ------------------------------ * Pagina 2 * -------------------------------------
                                  ,   'audit_land'                value adt.audit_land
                                  ,   'audit_stad'                value adt.audit_stad
                                  ,   'audit_straatnaam'          value adt.audit_straatnaam
                                ------------------------------ * Chart Data *  -------------------------------------
                                  ,   'colChart'                  value json_array(cch.chart_spec)
                                  ,   'stockChart'                value json_array(sch.chart_spec)
                                  ,   'timelineChart'             value json_array(tch.chart_spec)
                                  ,   'donutChart'                value json_array(dch.chart_spec)
                                        ------------ * Extra attributes for donut chart * ----------
                                  ,   'donut_chart_dagelijkse_pct'  value json_query(dch.donut_pct, '$[0]') -- * Dagelijkse
                                  ,   'donut_chart_cumulatief_pct'  value json_query(dch.donut_pct, '$[1]') -- * Cumulatief
                                  ,   'donut_chart_diverse_pct'     value '0.0%'                            -- * Diverse(hardcoded for now as no error types exist that fall into this category)
                                ------------------------------ * Table Data *  -------------------------------------
                                  ,   'audit_results'                       value ars_tbl.tbl_spec
                                  ,   'ruimteniveau_opmerkingen'            value rlc_tbl.tbl_spec
                                  ,   'algemene_opmerkingen'                value gnc_tbl.tbl_spec
                                  ,   'overige_hygienische_aspecten'        value ohc_tbl.tbl_spec
                                  ,   'ruimteniveau_opmerkingen_distribute' value true              --* Forgot what this does
                                ------------------------------ * HTML Data *  -------------------------------------
                                  ,   'htmlContent_use_tag_style'               value true
                                  ,   'htmlbettercontent_ignore_cell_margin'    value true
                                )
                            )
                )
         returning clob)as aop_data
,       adt.adt_id adt_id
,       adt.report_name
,       adt.audit_report_type
,       rlc_tbl.doc_ids
from w_adt                                  adt
join w_column_chart                         cch on adt.adt_id = cch.adt_id
join w_stock_chart                          sch on adt.adt_id = sch.adt_id
join w_timeline_chart                       tch on adt.adt_id = tch.main_adt_id
join w_donut_chart                          dch on adt.adt_id = dch.adt_id
join w_audit_results_tbl                    ars_tbl on ars_tbl.adt_id = adt.adt_id
join w_room_level_comments_tbl              rlc_tbl on rlc_tbl.adt_id = adt.adt_id
left join w_general_comments_tbl            gnc_tbl on gnc_tbl.adt_id = adt.adt_id
left join w_other_and_hygienic_comments_tbl ohc_tbl on ohc_tbl.adt_id = adt.adt_id
;

