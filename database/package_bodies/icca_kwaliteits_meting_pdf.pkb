create or replace package body icca_kwaliteits_meting_pdf
as
    --
    -- global variables
    gc_package        constant varchar2(31)   := $$plsql_unit|| '.';
    --
    --------------------------------------------------------------------------------------------------
    --
    function f_get_kmr_data( pi_audit_id in number )
    return icca_kwaliteits_meting_pdf_template.t_kwaliteits_meeting_values
    is
        --
        -- Algemeen Data
        --
        cursor c_fetch_data(b_audit_id in number)
        is
                select  adt.id                  as adt_id
                ,       adt.code                as audit_code
                ,       to_char(adt.audit_date, 'DD-MM-YYYY')          as audit_date
                ,       to_char(adt.audit_date, 'DD-MM-YYYY HH24:MI:SS') as controle_tijd
                ,       adt.active              as audit_active_ind
                ,       bch.name                as branch_name
                ,       cnt.company_name        as company_name
                ,       clt.contact_person      as contact_person
                ,       clt.name                as location_name
                ,       adt.type                as audit_type
                ,       adt.activate            as audit_activiate_ind
                ,       adt.audit_completed     as audit_completed_ind
                ,       case when prf.is_auditor = 'Y' then prf.first_name ||' '|| prf.last_name
                        else null end as auditor
                ,       trim(to_char(adt.audit_date, 'FMDD Mon YYYY', 'NLS_DATE_LANGUAGE = DUTCH')) as audit_volledige
                ,       clt.country
                ,       clt.city
                ,       clt.street_name
                from    icca_audits           adt
                join    icca_adt_forms        fom on fom.adt_id = adt.id
                join    icca_clients          cnt on adt.cnt_id = cnt.id
                join    icca_adt_performers   pef on pef.adt_id = adt.id
                join    icca_performers       prf on pef.pfr_id = prf.id
                join    icca_client_locations clt on adt.cln_id = clt.id
                join    icca_branches         bch on cnt.bch_id = bch.id
                where   adt.audit_completed = 'Y'
                and     adt.id               = b_audit_id
                ;
         --
         -- DJ grafiek data
         --
        cursor c_fetch_dj_grafiek(b_audit_id in number)
        is
                select  sum(case when lower(ete.name) = lower('niet gehecht vuil licht stof')   then er.error_count else 0 end) groen_1
                ,       sum(case when lower(ete.name) = lower('niet gehecht vuil methode')      then er.error_count else 0 end) groen_2
                ,       sum(case when lower(ete.name) = lower('aanslag')                        then er.error_count else 0 end) blauw_1
                ,       sum(case when lower(ete.name) = lower('dicht stof')                     then er.error_count else 0 end)  blauw_2
                ,       sum(case when lower(ete.name) = lower('gehecht vuil methode')           then er.error_count else 0 end)  blauw_3
                ,       sum(case when lower(ete.name) = lower('gehecht vuil vlek vingertast')   then er.error_count else 0 end)  blauw_4
                ,       sum(case when lower(ete.name) = lower('niet aangevuld')                 then er.error_count else 0 end)  bruin_1
                ,       sum(case when lower(ete.name) = lower('niet geleegd')                   then er.error_count else 0 end)  bruin_2
                ,       sum(case when lower(ete.name) = lower('spinrag')                        then er.error_count else 0 end)  bruin_3
                from  icca_adt_forms        fom
                join  icca_fom_errors       er  on er.fom_id  = fom.id
                join  icca_error_types      ete on ete.id     = er.ete_id
                join  icca_error_kinds      ekd on ekd.id     = ete.ekd_id
                join  icca_error_categories ece on ece.id     = ete.ece_id
                where  adt_id = b_audit_id
                ;
        --
        --
        --
        cursor c_fetch_donut_data (b_audit_id in number)
        is
                with total_errors as (
                select sum(er.error_count) as total
                from   icca_fom_errors er
                join   icca_adt_forms fom on fom.id = er.fom_id
                where  fom.adt_id = b_audit_id
                ),
                error_sums as (
                select
                    sum(case
                        when lower(ete.name) in ('niet gehecht vuil licht stof', 'niet gehecht vuil methode')
                        then er.error_count else 0
                    end) as groen_count,

                    sum(case
                        when lower(ete.name) in ('aanslag', 'gehecht vuil vlek vingertast', 'dicht stof', 'gehecht vuil methode')
                        then er.error_count else 0
                    end) as blauw_count,

                    sum(case
                        when lower(ete.name) in ('niet aangevuld', 'niet geleegd', 'spinrag')
                        then er.error_count else 0
                    end) as bruin_count

                from  icca_fom_errors er
                join  icca_adt_forms fom on fom.id = er.fom_id
                join  icca_error_types ete on ete.id = er.ete_id
                where fom.adt_id = b_audit_id
                )
                select
                to_char(round(groen_count * 100 / total.total, 1), 'fm99990.0') as groen,
                to_char(round(blauw_count * 100 / total.total, 1), 'fm99990.0') as blauw,
                to_char(round(bruin_count * 100 / total.total, 1), 'fm99990.0') as bruin
                from error_sums, total_errors total;
        --
        -- Data can de categories
        --
        cursor c_get_cat_data (b_audit_id in number)
        is
            select  cat.name              categorie
            ,       ars.counter_elements  tel_element
            ,       ars.counter_errors    fouten
            ,       ars.approve_limit     goedkeurgrens
            ,       case when ars.counter_errors >= ars.approve_limit then 'Onvoldoende' else 'Voldoende' end beoordeling
            from    icca_adt_results  ars
            join    icca_categories   cat on cat.id = ars.cat_id
            where   ars.adt_id = b_audit_id
            order by 1 desc
            ;
        --
        -- Data ruimte
        --
        cursor c_get_data_ruimte  (b_audit_id in number)
        is
            select   ruimte_nummer
                   , categorie
                   , element
                   , vuilsoort
                   , opmerking
                   , case
                        when log_book_image_id is not null then
                            row_number() over (order by log_book_image_id)
                    end as foto_nummer
            from (
                    select
                         flr.name || '-' || trim(ara.abbreviation) || '.' || fom.area_number as ruimte_nummer
                      ,  cat.name as categorie
                      ,  epe.name as element
                      ,  ete.name as vuilsoort
                      ,  err.log_book_remark as opmerking
                       , dir.id as log_book_image_id
                    from icca_adt_forms fom
                    join icca_floors flr on fom.flr_id = flr.id
                    join icca_categories cat on fom.cat_id = cat.id
                    join icca_areas ara on fom.ara_id = ara.id
                    join icca_fom_errors err on err.fom_id = fom.id
                    join icca_elementtypes epe on epe.id = err.epe_id
                    join icca_error_types ete on ete.id = err.ete_id
                    join icca_error_categories ece on ete.ece_id = ece.id
                    join icca_error_kinds ekd on ekd.id = ete.ekd_id
                    left join icca_documents dir on dir.id = err.log_book_image_id
                    where fom.adt_id = b_audit_id
                ) t
                ;

        --
        --  Data van de foto's
        --
        cursor c_get_data_images(b_audit_id in number)
        is
            select  dir.image_data as image
            ,       'Foto ' || row_number() over (order by dir.id) as foto_nummer
            from    icca_adt_forms  fom
            join    icca_fom_errors err   on err.fom_id = fom.id
            left join icca_documents dir on dir.id = err.log_book_image_id
            where   fom.adt_id = 101 ;
        --
        -- Aantal foto's
        --
        cursor c_aantal_fotos (b_audit_id in number)
        is
            select      count(err.log_book_image_id) as aantal
            from        icca_adt_forms  fom
            join        icca_fom_errors err   on err.fom_id = fom.id
            left join   icca_documents dir on dir.id = err.log_book_image_id
            where       fom.adt_id in (101) ;
        --
        -- variables
        --
        l_rte             icca_kwaliteits_meting_pdf_template.t_kwaliteits_meeting_values  := icca_kwaliteits_meting_pdf_template.t_kwaliteits_meeting_values();
        l_data            c_fetch_data%rowtype;
        l_dj_grafiek      c_fetch_dj_grafiek%rowtype;
        l_donut_data      c_fetch_donut_data%rowtype;
        l_aantal_fotos    c_aantal_fotos%rowtype;
        l_count           number := 0;
        l_count_1         number := 0;
        l_count_2         number := 0;
        --
        --
    begin
        --
        -- Open cursor om algemene data op tehalen
        --
        open  c_fetch_data(pi_audit_id);
        fetch c_fetch_data into l_data;
        close c_fetch_data;
        --
        l_rte.rapport_nummer        := l_data.audit_code;
        l_rte.datum                 := l_data.audit_date;
        l_rte.organisatie           := l_data.company_name;
        l_rte.tav                   := l_data.contact_person;
        l_rte.project_naam          := l_data.location_name;
        l_rte.tijdstip_controle     := l_data.controle_tijd;
        l_rte.controle_door         := l_data.auditor;
        l_rte.audit_volledige       := l_data.audit_volledige;
        l_rte.aanwezig_leverancier  := null;--i.
        l_rte.page_2_zin            := 'Op '||l_data.audit_volledige|| ' is in ' ||l_data.country||' gelegen aan de ' ||l_data.city|| ' te ' ||l_data.street_name||', de uitvoering van';
        --
        -- Open cursor om Dj grafiek data op tehalen
        --
        open  c_fetch_dj_grafiek(pi_audit_id);
        fetch c_fetch_dj_grafiek into l_dj_grafiek;
        close c_fetch_dj_grafiek;
        --
        l_rte.groen_1    := l_dj_grafiek.groen_1;
        l_rte.groen_2    := l_dj_grafiek.groen_2;
        l_rte.blauw_1    := l_dj_grafiek.blauw_1;
        l_rte.blauw_2    := l_dj_grafiek.blauw_2;
        l_rte.blauw_3    := l_dj_grafiek.blauw_3;
        l_rte.blauw_4    := l_dj_grafiek.blauw_4;
        l_rte.bruin_1    := l_dj_grafiek.bruin_1;
        l_rte.bruin_2    := l_dj_grafiek.bruin_2;
        l_rte.bruin_3    := l_dj_grafiek.bruin_3;
        --
        -- Open cursor om donut grafiek data op tehalen
        --
        open  c_fetch_donut_data(pi_audit_id);
        fetch c_fetch_donut_data into l_donut_data;
        close c_fetch_donut_data;
        --
        l_rte.donut_groen    := l_donut_data.groen||' '||'%';
        l_rte.donut_blauw    := l_donut_data.blauw||' '||'%';
        l_rte.donut_bruin    := l_donut_data.bruin||' '||'%';
        --
        -- Inital collection voor categorie data
        --
        l_rte.qte := icca_kwaliteits_meting_pdf_template.t_quality_values(icca_kwaliteits_meting_pdf_template.tt_quality_values(
               categorie    => null
            ,  tel_element   => null
            ,  goedkeurgrens => null
            ,  fouten        => null
            ,  beoordeling   => null
            )
            );

         --
         -- Data voor categorie
         --
        for l_qte_row in c_get_cat_data(pi_audit_id)
        loop
              l_count_1 := (l_count_1 + 1);
              l_rte.qte.extend;
                --
                l_rte.qte(l_count_1).categorie     := l_qte_row.categorie;
                l_rte.qte(l_count_1).tel_element   := l_qte_row.tel_element;
                l_rte.qte(l_count_1).goedkeurgrens := l_qte_row.goedkeurgrens;
                l_rte.qte(l_count_1).fouten        := l_qte_row.fouten;
                l_rte.qte(l_count_1).beoordeling   := l_qte_row.beoordeling;
            --
        end loop;
        --
        -- Initiaal data voor categorie data 2
        --
        l_rte.page4 := icca_kwaliteits_meting_pdf_template.t_page4_values(icca_kwaliteits_meting_pdf_template.tt_page4_values(
                ruimte_nummer    => null
            ,  categorie2        => null
            ,  element           => null
            ,  vuilsoort         => null
            ,  opmerking         => null
            ,  foto_nr           => null
            )
            );

        --
        --
        --
        for l_page4 in c_get_data_ruimte(pi_audit_id)
        loop
              l_count := (l_count + 1);
              l_rte.page4.extend;
                --
                l_rte.page4(l_count).ruimte_nummer    := l_page4.ruimte_nummer;
                l_rte.page4(l_count).categorie2       := l_page4.categorie;
                l_rte.page4(l_count).element          := l_page4.element;
                l_rte.page4(l_count).vuilsoort        := l_page4.vuilsoort;
                l_rte.page4(l_count).opmerking        := l_page4.opmerking;
                l_rte.page4(l_count).foto_nr          := l_page4.foto_nummer;
            --
        end loop;
         --
         -- Initaal voor foto's data
         --
            l_rte.image := icca_kwaliteits_meting_pdf_template.t_blob_values(icca_kwaliteits_meting_pdf_template.tt_blob_values(
                    tech_image    => null
                ,   foto_nummer  => null
                )
                );
         --
         --
         --
         for l_blob in c_get_data_images(pi_audit_id)
         loop
              l_count_2 := (l_count_2 + 1);
              l_rte.image.extend;
                --
                l_rte.image(l_count_2).tech_image     := l_blob.image;
                l_rte.image(l_count_2).foto_nummer    := l_blob.foto_nummer;
            --
         end loop;
        --
        -- Open cursor om aantal foto's op te halen
        --
        open  c_aantal_fotos(pi_audit_id);
        fetch c_aantal_fotos into l_aantal_fotos;
        close c_aantal_fotos;
        --
        l_rte.aantal_fotos    := l_aantal_fotos.aantal;
        --
        --
        return l_rte;
        --
        --
    exception
        when others then
        raise;
    end f_get_kmr_data;
    --
    --
    ---------------------------------------------------------------------------------------------------
    --
    -- create pdf for kwaliteits meeting rapport
    function f_kwaliteits_rapport_pdf(   pi_audit_id number )
    return blob
    is
        l_kte_data icca_kwaliteits_meting_pdf_template.t_kwaliteits_meeting_values :=  icca_kwaliteits_meting_pdf_template.t_kwaliteits_meeting_values();
        lb_retval blob;
    begin
            l_kte_data   := f_get_kmr_data (pi_audit_id => pi_audit_id);

            lb_retval := icca_kwaliteits_meting_pdf_template.f_get_kwaliteits_meting_pdf( p_kwaliteits_meeting_values => l_kte_data);
        --
        return lb_retval;
        --
    end f_kwaliteits_rapport_pdf;
    --
    --
    --
    ---------------------------------------------------------------------------------------------------
    --
end icca_kwaliteits_meting_pdf;
/