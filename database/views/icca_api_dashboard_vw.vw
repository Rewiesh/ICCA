create or replace view icca_api_dashboard_vw
as
    with w_aantal_audit_cnt_cln
    as  ( select  adt.code  as adt_code
        ,       cnt.id      as cnt_id
        ,       cln.id      as cln_id
        ,       count(1)    as adt_count
        from    icca_audits           adt
        join    icca_clients          cnt on adt.cnt_id = cnt.id
        join    icca_client_locations cln on adt.cln_id = cln.id
        group by adt.code
        ,       cnt.id
        ,       cln.id
    )
    ,     w_adt_results 
    as  ( select  /*+ MATERIALIZE*/
                ars.adt_id            as adt_id
        ,       cat.id                as cat_id          
        ,       ars.score             as score
        ,       ars.approve_limit     as approve_limit
        ,       ars.counter_elements  as counter_elements
        ,       ars.counter_errors    as counter_errors
        ,       cat.name              cat_name
        from    icca_adt_results      ars
        join    icca_categories       cat on ars.cat_id = cat.id
    )
    ,     w_adt_form
    as  ( select  fom.id                                                                        as id
        ,       fom.migrated_data                                                               as migrated_data
        ,       fom.migrated_area_code                                                          as migrated_area_code
        ,       flr.name||'-'||ara.abbreviation||'.'||fom.area_number                           as Formulier_omschrijving
        ,       flr.name                                                                        as verdieping
        ,       ara.abbreviation                                                                as ruimte_omschrijving    
        ,       fom.area_number                                                                 as ruimte_nummer
        ,       cat.id                                                                          as cat_id
        ,       cat.name                                                                        as categorie
        ,       fom.element_count                                                               as tel_elementen
        ,       fom.remark                                                                      as opmerking
        ,       nvl((select sum(error_count) from icca_fom_errors where fom_id = fom.id), 0)    as aantal_fouten
        ,       fom.adt_id                                                                      as adt_id
        ,       epe.name                                                                        as element_type
        ,       ete.name                                                                        as error_type
        ,       fer.error_count                                                                 as error_count
        from    icca_adt_forms      fom
        join    icca_floors         flr on fom.flr_id = flr.id
        join    icca_categories     cat on fom.cat_id = cat.id
        join    icca_areas          ara on fom.ara_id = ara.id
        left join icca_fom_errors   fer on fer.fom_id = fom.id
        left join icca_elementtypes epe on fer.epe_id = epe.id
        left join icca_error_types  ete on fer.ete_id = ete.id
    )
    select  cnt.id                                                              as CompanyId
    ,       adt.id                                                              as AuditId
    ,       fom.id                                                              as FomId
    ,       cnt.company_name                                                    as CompanyName
    ,       cln.name                                                            as Name
    ,       cln.province                                                        as Region
    ,       adt.last_control_date                                               as AuditUitgevoerdDatum
    ,       adt.code                                                            as AuditCode
    ,       fom.categorie                                                       as CategoryName
    ,       case 
                when fom.migrated_data = 'Y' then fom.migrated_area_code
                else fom.formulier_omschrijving
            end                                                                 as AreaCode  
    ,       6                                                                   as GKGrens
    ,       round(ars.score, 1)                                                 as Resultaat
    ,       fom.element_type                                                    as ElementTypeValue
    ,       fom.error_type                                                      as ErrorTypeValue
    ,       fom.error_count                                                     as fout
    ,       extract (year from adt.last_control_date)                           as jaar
    ,       case 
                when row_number() over (partition by cnt.company_name, cln.name, adt.code 
                                        order by error_type nulls first, fom.categorie, fom.formulier_omschrijving) = 1 
                then ooo.adt_count 
                else null 
            end                                                                 as aantal_contr
    from    icca_audits             adt
    join    icca_clients            cnt on adt.cnt_id = cnt.id
    join    icca_client_locations   cln on adt.cln_id = cln.id
    join    w_adt_form              fom on fom.adt_id = adt.id
    join    w_aantal_audit_cnt_cln  ooo on ooo.adt_code = adt.code
    left join w_adt_results         ars on ars.adt_id = adt.id and ars.cat_id = fom.cat_id
    where   adt.activate = 'Y'
    and     cnt.send_data_to_dashboard = 'Y'
    and     adt.last_control_date is not null
    order by areacode
;