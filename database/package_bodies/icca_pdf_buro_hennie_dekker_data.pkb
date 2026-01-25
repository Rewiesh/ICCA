create or replace package body icca_pdf_buro_hennie_dekker_data as
    --
    -- Private constants
    --
    c_base_url constant varchar2(100) := 'http://localhost:3000'; -- Aanpassen naar echte URL indien nodig

    --
    -- Helper: Formatteer datum
    --
    function f_format_date (
        p_date in date
    ) return varchar2 is
    begin
        return to_char(
            p_date,
            'DD-MM-YYYY'
        );
    end f_format_date;

    --
    -- Helper: Formatteer tijd
    --
    function f_format_time (
        p_date in date
    ) return varchar2 is
    begin
        return to_char(
            p_date,
            'HH24:MI'
        );
    end f_format_time;

    --
    -- Helper: Bepaal week/jaar string (bijv. "wk 16-2025")
    --
    function f_get_week_year (
        p_date in date
    ) return varchar2 is
    begin
        return 'wk ' || to_char(
            p_date,
            'IW-YYYY'
        );
    end f_get_week_year;

    --
    -- Helper: Bepaal week/jaar string (bijv. "16-2025")
    --
    function f_get_week_year_2 (
        p_date in date
    ) return varchar2 is
    begin
        return to_char(
            p_date,
            'IW-YYYY'
        );
    end f_get_week_year_2;

    --
    -- 1. Audit Info
    --
    function f_get_audit_info (
        p_adt_id in number
    ) return json_object_t is
            --
        cursor c_documents (
            b_doc_id in number
        ) is
        select doc.file_url
            from icca_documents doc
        where doc.id = b_doc_id;
            --
        l_obj              json_object_t := json_object_t();
        l_audit_rec        icca_audits%rowtype;
        l_handtekening_url varchar2(4000);
        l_client_rec       icca_clients%rowtype;
        l_location_rec     icca_client_locations%rowtype;
        l_client_logo_url  varchar2(4000);
        l_performer_name   varchar2(200);
        l_present_client   varchar2(200);
    begin
        -- Haal audit, client en locatie op
        select adt.*
            into l_audit_rec
            from icca_audits adt
        where adt.id = p_adt_id;

        select cnt.*
            into l_client_rec
            from icca_clients cnt
        where cnt.id = l_audit_rec.cnt_id;

        select cln.*
            into l_location_rec
            from icca_client_locations cln
        where cln.id = l_audit_rec.cln_id;

        -- Haal uitvoerder op (uit adt_forms)
        begin
            select pfr.first_name
                    || ' '
                    || pfr.last_name
            into l_performer_name
            from icca_adt_forms fom
            join icca_performers pfr
            on pfr.id = fom.pfr_id
            where fom.adt_id = p_adt_id
            fetch first 1 row only;
        exception
            when others then
                l_performer_name := 'Onbekend';
        end;  

        -- Haal aanwezige klant op (eerste)
        begin
            select
                listagg(apt.name,
                        ', ') within group(
                order by apt.name)
            into l_present_client
            from icca_adt_present_clients apt
            where apt.adt_id = p_adt_id;
        exception
            when others then
                l_present_client := '';
        end;

        -- Haal handtekening op
        open c_documents(l_audit_rec.signature_image_id);
        fetch c_documents into l_handtekening_url;
        close c_documents;

        -- Haal client logo op
        open c_documents(l_client_rec.logo_id);
        fetch c_documents into l_client_logo_url;
        close c_documents;
        l_obj.put(
            'rapport_titel',
            'Rapportage '
            || l_audit_rec.type
            || ' '
            || f_get_week_year(l_audit_rec.last_control_date)
            || ' '
            || l_client_rec.company_name
        );
        l_obj.put(
            'opdrachtgever',
            l_client_rec.company_name
        );
        -- Adresgegevens (aanname kolomnamen, aanpassen indien nodig)
        l_obj.put(
            'adres',
            nvl(
                l_location_rec.street_name,
                l_client_rec.street_name
            )
        );
        l_obj.put(
            'postcode_plaats',
            nvl(
                l_location_rec.name,
                ''
            )
        );
        l_obj.put(
            'plaats',
            nvl(
                l_location_rec.city,
                l_client_rec.city
            )
        );
        l_obj.put(
            'tav',
            nvl(
                l_location_rec.contact_person,
                l_client_rec.contact_person
            )
        );
        l_obj.put(
            'controle_uitgevoerd_op',
            f_format_date(l_audit_rec.last_control_date)
        );
        l_obj.put(
            'controle_periode',
            f_get_week_year(l_audit_rec.last_control_date)
        );
        l_obj.put(
            'tijdstip_controle',
            f_format_time(l_audit_rec.last_control_date)
        );
        l_obj.put(
            'controlenummer',
            l_audit_rec.code
        );
        -- PDF filename: audit_code.klant_naam.locatie_code
        l_obj.put(
            'pdf_filename',
            l_audit_rec.code
            || '.'
            || l_client_rec.company_name
            || '.'
            || nvl(
                l_location_rec.name,
                'Onbekend'
            )
        );
        l_obj.put(
            'uitgevoerd_door', -- aanwezig bij audit
            nvl(
                l_present_client,
                ''
            )
        );
        l_obj.put(
            'controle_uitgevoerd_door',
            l_performer_name
        );

        -- Images
        if l_client_rec.logo_id is not null then
            l_obj.put(
                'client_logo_url',
                c_base_url || l_client_logo_url
            ); -- Extensie?
        else
            l_obj.put(
                'client_logo_url',
                ''
            );
        end if;

        if l_audit_rec.signature_image_id is not null then
            l_obj.put(
                'handtekening_url',
                c_base_url || l_handtekening_url
            );
        else
            l_obj.put(
                'handtekening_url',
                ''
            );
        end if;

        return l_obj;
    exception
        when no_data_found then
            return json_object_t(); -- Leeg object bij fout
    end f_get_audit_info;

    --
    -- 2. Categories
    --
    function f_get_categories (
        p_adt_id in number
    ) return json_array_t is
        l_arr json_array_t := json_array_t();
        l_obj json_object_t;
    begin
        for r in (
            select cat.name as categorie_naam,
                    res.counter_elements as tel_element,
                    res.approve_limit as goedkeurgrens,
                    res.counter_errors as aantal_behaalde_fouten,
                    res.score as cijfer,
                    case
                    when res.is_sufficient = 'Y' then
                        'Voldoende'
                    else
                        'Onvoldoende'
                    end as beoordeling
            from icca_adt_results res
            join icca_categories cat
            on cat.id = res.cat_id
            where res.adt_id = p_adt_id
            order by cat.name -- Of een andere volgorde
        ) loop
            l_obj := json_object_t();
            l_obj.put(
                'categorie_naam',
                r.categorie_naam
            );
            l_obj.put(
                'tel_element',
                r.tel_element
            );
            l_obj.put(
                'goedkeurgrens',
                r.goedkeurgrens
            );
            l_obj.put(
                'aantal_behaalde_fouten',
                r.aantal_behaalde_fouten
            );
            l_obj.put(
                'cijfer',
                round(
                r.cijfer,
                2
                )
            );
            l_obj.put(
                'beoordeling',
                r.beoordeling
            );
            l_arr.append(l_obj);
        end loop;
        return l_arr;
    end f_get_categories;

    --
    -- 3. Average Grade Data (Historie)
    --
    function f_get_average_grade_data (
        p_adt_id in number
    ) return json_array_t is
        l_arr    json_array_t := json_array_t();
        l_obj    json_object_t;
        l_cnt_id number;
    begin
        -- Haal client ID op
        select cnt_id
            into l_cnt_id
            from icca_audits
        where id = p_adt_id;

        -- Haal laatste 8 audits op voor deze klant (inclusief huidige?)
        for r in (
            select *
            from (
                select adt.last_control_date,
                    adt.code,
                    (
                        select avg(score)
                            from icca_adt_results
                        where adt_id = adt.id
                    ) as gem_cijfer
                from icca_audits adt
                where adt.cnt_id = l_cnt_id
                and adt.audit_completed = 'Y'
                and adt.last_control_date <= (
                select last_control_date
                    from icca_audits
                    where id = p_adt_id
                )
                order by adt.last_control_date desc
            )
            where rownum <= 8
            order by last_control_date asc
        ) loop
            l_obj := json_object_t();
            l_obj.put(
                'periode',
                r.code
                || ' '
                || f_get_week_year_2(r.last_control_date)
            ); -- Of datum formaat
            l_obj.put(
                'cijfer',
                round(
                r.gem_cijfer,
                1
                )
            );
            l_arr.append(l_obj);
        end loop;
        return l_arr;
    end f_get_average_grade_data;

    --
    -- 4. Most Common Faults
    --
    function f_get_most_common_faults (
        p_adt_id in number
    ) return json_array_t is
        l_arr        json_array_t := json_array_t();
        l_cat_obj    json_object_t;
        l_fouten_arr json_array_t;
        l_fout_obj   json_object_t;
    begin
        -- Loop per categorie die fouten heeft
        for r_cat in (
            select distinct cat.id,
                            cat.name
            from icca_adt_forms fom
            join icca_categories cat
            on cat.id = fom.cat_id
            where fom.adt_id = p_adt_id
                and fom.error_count > 0
            order by cat.name
        ) loop
            l_cat_obj := json_object_t();
            l_cat_obj.put(
                'categorie_naam',
                r_cat.name
            );
            l_fouten_arr := json_array_t();

    -- Haal top 7 fouten op voor deze categorie
            for r_err in (
                select *
                from (
                select epe.name as element_naam,
                    -- ALLEEN fouten die GEEN methode-fout zijn
                        sum(
                            case
                                when ece.name = 'methode-fout' then
                                0
                                else
                                err.error_count
                            end
                        ) as aantal,
                    -- Bereken aantal methode fouten voor dit element
                        sum(
                            case
                                when ece.name = 'methode-fout' then
                                err.error_count
                                else
                                0
                            end
                        ) as methode_count
                    from icca_fom_errors err
                    join icca_adt_forms fom
                on fom.id = err.fom_id
                    join icca_elementtypes epe
                on epe.id = err.epe_id
                    join icca_error_types ete
                on ete.id = err.ete_id
                    join icca_error_categories ece
                on ece.id = ete.ece_id
                    where fom.adt_id = p_adt_id
                    and fom.cat_id = r_cat.id
                    and ( err.added_default_ete_id is null
                    and err.added_default_epe_id is null )
                    group by epe.name
                -- BELANGRIJK: Sorteer op totale fouten (aantal + methode samen) om top 7 te bepalen
                    order by sum(err.error_count) desc
                )
                where rownum <= 7
            ) loop
                l_fout_obj := json_object_t();
                l_fout_obj.put(
                'element',
                r_err.element_naam
                );
                l_fout_obj.put(
                'aantal',
                r_err.aantal  -- Kan 0 zijn als er alleen methode-fouten zijn
                );
                l_fout_obj.put(
                'methode',
                r_err.methode_count  -- Aantal methode fouten als NUMBER
                );
                l_fouten_arr.append(l_fout_obj);
            end loop;
            l_cat_obj.put(
                'fouten',
                l_fouten_arr
            );
            l_arr.append(l_cat_obj);
        end loop;
        return l_arr;
    end f_get_most_common_faults;

    --
    -- 5. Element Fouten Top
    --
    function f_elementen_fouten_top (
        p_adt_id in number
    ) return json_array_t is
        l_arr          json_array_t := json_array_t();
        l_obj          json_object_t;
        l_total_errors number := 0;
    begin
        -- Totaal aantal fouten
        select sum(error_count)
            into l_total_errors
            from icca_adt_forms
        where adt_id = p_adt_id;

        if l_total_errors = 0 then
            return l_arr;
        end if;
        for r in (
            select epe.name as label,
                    sum(err.error_count) as aantal
            from icca_fom_errors err
            join icca_adt_forms fom
            on fom.id = err.fom_id
            join icca_elementtypes epe
            on epe.id = err.epe_id
            where fom.adt_id = p_adt_id
                and ( err.added_default_ete_id is null
                and err.added_default_epe_id is null )
            group by epe.name
            order by sum(err.error_count) desc
            fetch first 7 rows only
        ) loop
            l_obj := json_object_t();
            l_obj.put(
                'label',
                r.label
            );
            l_obj.put(
                'score',
                round(
                (r.aantal / l_total_errors) * 100,
                2
                )
            );
            l_arr.append(l_obj);
        end loop;
        return l_arr;
    end f_elementen_fouten_top;   

    --
    -- 6. Pareto Data
    --
    function f_get_pareto_data (
        p_adt_id in number
    ) return json_array_t is
        l_arr           json_array_t := json_array_t();
        l_obj           json_object_t;
        l_total_errors  number := 0;
        l_running_total number := 0;
    begin
            -- Totaal aantal fouten
        select sum(error_count)
            into l_total_errors
            from icca_adt_forms
        where adt_id = p_adt_id;

        if l_total_errors = 0 then
            return l_arr;
        end if;
        for r in (
            select epe.name as label,
                    sum(err.error_count) as aantal
            from icca_fom_errors err
            join icca_adt_forms fom
            on fom.id = err.fom_id
            join icca_elementtypes epe
            on epe.id = err.epe_id
            where fom.adt_id = p_adt_id
                and ( err.added_default_ete_id is null
                and err.added_default_epe_id is null )
            group by epe.name
            order by sum(err.error_count) desc
            fetch first 7 rows only
        ) loop
            l_running_total := l_running_total + r.aantal;
            l_obj := json_object_t();
            l_obj.put(
                'label',
                r.label
            );
            l_obj.put(
                'aantal',
                r.aantal
            );
            l_obj.put(
                'percentage',
                round(
                (l_running_total / l_total_errors) * 100,
                2
                )
            );
            l_arr.append(l_obj);
        end loop;
        return l_arr;
    end f_get_pareto_data;

    --
    -- 6. Vuilsoorten Resultaten
    --
    function f_get_vuilsoorten_resultaten (
        p_adt_id in number
    ) return json_array_t is
        l_arr          json_array_t := json_array_t();
        l_obj          json_object_t;
        l_total_errors number;
    begin
        -- Eerst het totaal aantal fouten (SUM van error_count, niet COUNT)
        select sum(frr.error_count)
            into l_total_errors
            from icca_fom_errors frr
            join icca_adt_forms fom
        on fom.id = frr.fom_id
        where fom.adt_id = p_adt_id
            and ( frr.added_default_ete_id is null
            and frr.added_default_epe_id is null );

        -- Dan per vuilsoort het percentage berekenen
        -- LEFT JOIN om ALLE error types te tonen (ook met 0%)
        for rec in (
            select ete.name as label,
                    case
                    when l_total_errors > 0 then
                        round(
                            (sum(nvl(
                                frr.error_count,
                                0
                            )) * 100.0) / l_total_errors,
                            2
                        )
                    else
                        0
                    end as score
            from icca_error_types ete
            left join (
                select frr2.ete_id,
                    frr2.error_count
                from icca_fom_errors frr2
                join icca_adt_forms fom2
                on fom2.id = frr2.fom_id
                where fom2.adt_id = p_adt_id
                and ( frr2.added_default_ete_id is null
                and frr2.added_default_epe_id is null )
            ) frr
            on frr.ete_id = ete.id
            group by ete.id,
                    ete.name
            order by ete.name
        ) loop
            l_obj := json_object_t();
            l_obj.put(
                'label',
                rec.label
            );
            l_obj.put(
                'score',
                rec.score
            );
            l_arr.append(l_obj);
        end loop;
        return l_arr;
    end f_get_vuilsoorten_resultaten;

    --
    -- 7. Foutsoorten Resultaten
    --
    function f_get_foutsoorten_resultaten (
        p_adt_id in number
    ) return json_array_t is
        l_arr          json_array_t := json_array_t();
        l_obj          json_object_t;
        l_total_errors number;
    begin
        -- Eerst het totaal aantal fouten (SUM van error_count, niet COUNT)
        select sum(frr.error_count)
            into l_total_errors
            from icca_fom_errors frr
            join icca_adt_forms fom
        on fom.id = frr.fom_id
        where fom.adt_id = p_adt_id
            and ( frr.added_default_ete_id is null
            and frr.added_default_epe_id is null );

        -- Dan per foutsoort/categorie het percentage berekenen (UNION)
        -- LEFT JOIN om ALLE types te tonen (ook met 0%)
        for rec in (
        
            -- ERROR CATEGORIES (icca_error_categories)
            select ece.name as label,
                    case
                    when l_total_errors > 0 then
                        round(
                            (sum(nvl(
                                frr.error_count,
                                0
                            )) * 100.0) / l_total_errors,
                            2
                        )
                    else
                        0
                    end as score,
                    2 as sort_order  -- Voor sortering: categories daarna
            from icca_error_categories ece
            left join icca_error_types ete
            on ete.ece_id = ece.id
            left join (
                select frr2.ete_id,
                    frr2.error_count
                from icca_fom_errors frr2
                join icca_adt_forms fom2
                on fom2.id = frr2.fom_id
                where fom2.adt_id = p_adt_id
                and ( frr2.added_default_ete_id is null
                and frr2.added_default_epe_id is null )
            ) frr
            on frr.ete_id = ete.id
            group by ece.id,
                    ece.name
            union all            
            -- ERROR KINDS (icca_error_kinds)
            select ekd.name as label,
                    case
                    when l_total_errors > 0 then
                        round(
                            (sum(nvl(
                                frr.error_count,
                                0
                            )) * 100.0) / l_total_errors,
                            2
                        )
                    else
                        0
                    end as score,
                    1 as sort_order  -- Voor sortering: kinds eerst
            from icca_error_kinds ekd
            left join icca_error_types ete
            on ete.ekd_id = ekd.id
            left join (
                select frr2.ete_id,
                    frr2.error_count
                from icca_fom_errors frr2
                join icca_adt_forms fom2
                on fom2.id = frr2.fom_id
                where fom2.adt_id = p_adt_id
                and ( frr2.added_default_ete_id is null
                and frr2.added_default_epe_id is null )
            ) frr
            on frr.ete_id = ete.id
            group by ekd.id,
                    ekd.name
            order by sort_order,
                    label
        ) loop
            l_obj := json_object_t();
            l_obj.put(
                'label',
                rec.label
            );
            l_obj.put(
                'score',
                rec.score
            );
            l_arr.append(l_obj);
        end loop;
        return l_arr;
    end f_get_foutsoorten_resultaten;

    --
    -- 8. Gecontroleerde ruimtes
    --
    function f_get_gecontroleerde_ruimtes (
        p_adt_id in number
    ) return json_array_t is
        l_arr json_array_t := json_array_t();
    begin
        for rec in (
            select case
                    when fom.migrated_data = 'Y' then
                        fom.migrated_area_code
                    else
                        flr.name
                        || '-'
                        || ara.abbreviation
                        || '.'
                        || fom.area_number
                    end as ruimte
            from icca_adt_forms fom
            join icca_floors flr
            on fom.flr_id = flr.id
            join icca_categories cat
            on fom.cat_id = cat.id
            join icca_areas ara
            on fom.ara_id = ara.id
            where fom.adt_id = p_adt_id
            order by ruimte
        ) loop
            l_arr.append(rec.ruimte);
        end loop;

        return l_arr;
    end f_get_gecontroleerde_ruimtes;

    --
    -- 9. Opmerkingen
    --
    function f_get_opmerkingen (
        p_adt_id in number
    ) return json_array_t is
        l_arr json_array_t := json_array_t();
        l_obj json_object_t;
    begin
        for rec in (
            select case
                    when fom.migrated_data = 'Y' then
                        fom.migrated_area_code
                    else
                        flr.name
                        || '-'
                        || ara.abbreviation
                        || '.'
                        || fom.area_number
                    end as ruimte,
                    fom.remark as tekst
            from icca_adt_forms fom
            join icca_floors flr
            on fom.flr_id = flr.id
            join icca_categories cat
            on fom.cat_id = cat.id
            join icca_areas ara
            on fom.ara_id = ara.id
            where fom.adt_id = p_adt_id
                and fom.remark is not null
            order by ruimte
        ) loop
            l_obj := json_object_t();
            l_obj.put(
                'ruimte',
                rec.ruimte
            );
            l_obj.put(
                'tekst',
                rec.tekst
            );
            l_arr.append(l_obj);
        end loop;

        return l_arr;
    end f_get_opmerkingen;

    --
    -- 10. Pareto Info
    --
    function f_get_pareto_info (
        p_adt_id in number
    ) return json_object_t is
        l_obj        json_object_t := json_object_t();
        l_pareto_arr json_array_t;
        l_count      number := 0;
        l_names      varchar2(4000) := '';
        l_perc       number := 0;
    begin
        l_pareto_arr := f_get_pareto_data(p_adt_id);
        
        -- Logica: pak items totdat cumulatief percentage >= 60% bereikt
        -- Het percentage in de data is al cumulatief (running total)
        for i in 0..l_pareto_arr.get_size - 1 loop
            declare
                l_item         json_object_t;
                l_current_perc number;
            begin
                l_item := treat(l_pareto_arr.get(i) as json_object_t);
                l_current_perc := l_item.get_number('percentage');
            
                -- Voeg item toe
                l_count := l_count + 1;
                if l_names is not null then
                    l_names := l_names || ' en ';  -- Gebruik 'en' i.p.v. komma voor laatste scheiding
                end if;
                l_names := l_names || l_item.get_string('label');
                l_perc := l_current_perc;
            
                -- Stop als we >= 60% bereikt hebben
                if l_current_perc >= 60 then
                    exit;
                end if;
            end;
        end loop;
        l_obj.put(
            'aantal_elementen',
            l_count
        );
        l_obj.put(
            'element_namen',
            l_names
        );
        l_obj.put(
            'totaal_percentage',
            l_perc
        );
        return l_obj;
    end f_get_pareto_info;

    --
    -- 11. Remarks Logbook
    --
    function f_get_remarks_logbook (
        p_adt_id in number
    ) return json_array_t is
        l_arr json_array_t := json_array_t();
        l_obj json_object_t;
    begin
        for r in (
            select distinct
                case
                when fom.migrated_data = 'Y' then
                    fom.migrated_area_code
                else
                    flr.name
                    || '-'
                    || ara.abbreviation
                    || '.'
                    || fom.area_number
                end
                || ': '
                || epe.name
                || ' '
                || ete.name
                || ', '
                || err.log_book_remark as tekst
            from icca_fom_errors err
            join icca_adt_forms fom
            on fom.id = err.fom_id
            join icca_elementtypes epe
            on epe.id = err.epe_id
            join icca_error_types ete
            on ete.id = err.ete_id
            join icca_floors flr
            on fom.flr_id = flr.id
            join icca_areas ara
            on fom.ara_id = ara.id
            where fom.adt_id = p_adt_id
                and err.log_book_remark is not null
                and ( err.added_default_ete_id is null
                and err.added_default_epe_id is null )
            order by 1
        ) loop
            l_obj := json_object_t();
            l_obj.put(
                'tekst',
                r.tekst
            );
            l_arr.append(l_obj);
        end loop;
        return l_arr;
    end f_get_remarks_logbook;

    --
    -- 12. Logbook Photos
    --
    function f_get_logbook_photos (
        p_adt_id in number
    ) return json_array_t is
        l_arr          json_array_t := json_array_t();
        l_obj          json_object_t;
        l_count        number := 0;
        l_base64_data  clob;
    begin
        for r in (
            select distinct doc.file_url as image_url,
                            err.log_book_remark as beschrijving
            from icca_fom_errors err
            join icca_adt_forms fom
            on fom.id = err.fom_id
            join icca_documents doc
            on doc.id = err.log_book_image_id
            where fom.adt_id = p_adt_id
                and err.log_book_image_id is not null
                and doc.file_url is not null
        ) loop
            -- Get Base64 image data
            l_base64_data := icca_file_upload.f_get_image_base64(r.image_url);
            
            if l_base64_data is not null then
                l_count := l_count + 1;
                l_obj := json_object_t();
                l_obj.put('base64_data', l_base64_data);
                l_obj.put('beschrijving', nvl(r.beschrijving, null));
                
                -- Page break every 6 photos (2 rows of 3 columns)
                l_obj.put(
                'page_break',
                case
                    when mod(l_count - 1, 6) = 0 and l_count > 1 then true
                    else false
                end
                );
                l_arr.append(l_obj);
            end if;
        end loop;
        return l_arr;
    end f_get_logbook_photos;

    --
    -- 13. Technical Remarks
    --
    function f_get_technical_remarks (
        p_adt_id in number
    ) return json_array_t is
        l_arr json_array_t := json_array_t();
        l_obj json_object_t;
    begin
        for r in (
            select distinct
                case
                when fom.migrated_data = 'Y' then
                    fom.migrated_area_code
                else
                    flr.name
                    || '-'
                    || ara.abbreviation
                    || '.'
                    || fom.area_number
                end
                || ': '
                || err.technical_aspects_remark as tekst
            from icca_fom_errors err
            join icca_adt_forms fom
            on fom.id = err.fom_id
            join icca_floors flr
            on fom.flr_id = flr.id
            join icca_areas ara
            on fom.ara_id = ara.id
            where fom.adt_id = p_adt_id
                and err.technical_aspects_remark is not null
                and ( err.added_default_ete_id is null
                and err.added_default_epe_id is null )
            union all
            select  fom.areacode ||': ' || rmk.remarktext  as beschrijving
            from    auditremarks2 rmk
            join    audits2 adt on adt.id = rmk.auditid
            join    forms2 fom on fom.id = rmk.formid
            join    images2 img2 on img2.imageid = remarkimage
            where   adt.adt_id = p_adt_id
            -- and     img2.doc_id is not null
            union all
            select  case
                        when fom.migrated_data = 'Y' then fom.migrated_area_code
                        else flr.name || '-' || ara.abbreviation || '.' || fom.area_number
                    end || ': ' || fmr.remark_text as beschrijving
            from    icca_form_remarks fmr
            join    icca_adt_forms fom on fom.id = fmr.fom_id
            join    icca_floors flr on fom.flr_id = flr.id
            join    icca_areas ara on fom.ara_id = ara.id
            where   fom.adt_id = p_adt_id                
            order by 1
        ) loop
            l_obj := json_object_t();
            l_obj.put(
                'tekst',
                r.tekst
            );
            l_arr.append(l_obj);
        end loop;
        return l_arr;
    end f_get_technical_remarks;

    --
    -- 14. Technical Photos
    --
    function f_get_technical_photos (
        p_adt_id in number
    ) return json_array_t is
        l_arr          json_array_t := json_array_t();
        l_obj          json_object_t;
        l_file_url     varchar2(4000);
        l_count        number := 0;
        l_base64_data  clob;
    begin
        for r in (
            select distinct err.technical_aspects_image_id as image_id,
                            err.technical_aspects_remark as beschrijving
            from icca_fom_errors err
            join icca_adt_forms fom
            on fom.id = err.fom_id
            where fom.adt_id = p_adt_id
                and err.technical_aspects_image_id is not null
            union all
            select  img2.doc_id     as image_id
            ,       fom.areacode ||': ' || rmk.remarktext  as beschrijving
            from    auditremarks2 rmk
            join    audits2 adt on adt.id = rmk.auditid
            join    forms2 fom on fom.id = rmk.formid
            join    images2 img2 on img2.imageid = remarkimage
            where   adt.adt_id = p_adt_id
            -- and     img2.doc_id is not null
            union all
            select  fmr.remark_image_id     as image_id
            ,       case
                        when fom.migrated_data = 'Y' then fom.migrated_area_code
                        else flr.name || '-' || ara.abbreviation || '.' || fom.area_number
                    end || ': ' || fmr.remark_text as beschrijving
            from    icca_form_remarks fmr
            join    icca_adt_forms fom on fom.id = fmr.fom_id
            join    icca_floors flr on fom.flr_id = flr.id
            join    icca_areas ara on fom.ara_id = ara.id
            where   fom.adt_id = p_adt_id                
        ) loop
            -- Get file_url from icca_documents
            begin
                select doc.file_url
                into l_file_url
                from icca_documents doc
                where doc.id = r.image_id
                and doc.file_url is not null;
            exception
                when no_data_found then
                l_file_url := null;
            end;
            
            -- Only add if we have a valid URL and can convert to Base64
            if l_file_url is not null then
                l_base64_data := icca_file_upload.f_get_image_base64(l_file_url);
                
                if l_base64_data is not null then
                l_count := l_count + 1;
                l_obj := json_object_t();
                l_obj.put('base64_data', l_base64_data);
                l_obj.put('beschrijving', nvl(r.beschrijving, null));
                
                -- Page break every 6 photos (2 rows of 3 columns)
                l_obj.put(
                    'page_break',
                    case
                        when mod(l_count - 1, 6) = 0 and l_count > 1 then true
                        else false
                    end
                );
                l_arr.append(l_obj);
                end if;
            end if;
        end loop;
        return l_arr;
    end f_get_technical_photos;

    --
    -- 15. KPI Subjects
    --
    function f_get_kpi_subjects (
        p_adt_id in number
    ) return json_array_t is
        l_arr json_array_t := json_array_t();
        l_obj json_object_t;
    begin
        for r in (
            select element_label as algemeen,
                    element_value as status,
                    element_comment as opmerkingen
            from icca_adt_kpi_elements
            where adt_id = p_adt_id
        ) loop
            l_obj := json_object_t();
            l_obj.put(
                'algemeen',
                r.algemeen
            );
            l_obj.put(
                'status',
                r.status
            );
            l_obj.put(
                'opmerkingen',
                r.opmerkingen
            );
            l_arr.append(l_obj);
        end loop;
        return l_arr;
    end f_get_kpi_subjects;

    --
    -- Main: Generate Full JSON
    --
    function f_get_main_json (
        p_adt_id in number
    ) return clob is
        l_root json_object_t;
        l_data json_object_t;
    begin
        l_root := json_object_t();
        l_data := json_object_t();
        l_root.put(
            'template_name',
            'BURO_HENNIE_DEKKER'
        );
            
            -- Build data object
        l_data.put(
            'audit_info',
            f_get_audit_info(p_adt_id)
        );
        l_data.put(
            'categories',
            f_get_categories(p_adt_id)
        );
        l_data.put(
            'gemiddeld_cijfer_data',
            f_get_average_grade_data(p_adt_id)
        );
        l_data.put(
            'meest_voorkomende_fouten',
            f_get_most_common_faults(p_adt_id)
        );
        l_data.put(
            'vuilsoorten_resultaten',
            f_get_vuilsoorten_resultaten(p_adt_id)
        );
        l_data.put(
            'foutsoorten_resultaten',
            f_get_foutsoorten_resultaten(p_adt_id)
        );
        l_data.put(
            'gecontroleerde_ruimtes',
            f_get_gecontroleerde_ruimtes(p_adt_id)
        );
        l_data.put(
            'opmerkingen',
            f_get_opmerkingen(p_adt_id)
        );
        l_data.put(
            'element_fouten_top',
            f_elementen_fouten_top(p_adt_id)
        );
        l_data.put(
            'pareto_data',
            f_get_pareto_data(p_adt_id)
        );
        l_data.put(
            'pareto_info',
            f_get_pareto_info(p_adt_id)
        );
        l_data.put(
            'opmerkingen_logboek',
            f_get_remarks_logbook(p_adt_id)
        );
        l_data.put(
            'logboek_fotos',
            f_get_logbook_photos(p_adt_id)
        );
        l_data.put(
            'opmerkingen_gebouwtechnisch',
            f_get_technical_remarks(p_adt_id)
        );
        l_data.put(
            'fotos_gebouwtechnisch',
            f_get_technical_photos(p_adt_id)
        );
        l_data.put(
            'kpi_onderwerpen',
            f_get_kpi_subjects(p_adt_id)
        );
        l_root.put(
            'data',
            l_data
        );
        return l_root.to_clob();
    end f_get_main_json;

end icca_pdf_buro_hennie_dekker_data;
/