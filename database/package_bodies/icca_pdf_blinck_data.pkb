create or replace package body icca_pdf_blinck_data as
    --
    -- Private constants
    --
    c_config_key_pdf_url constant varchar2(100) := 'PDF_SERVICE_URL';
    c_default_pdf_url    constant varchar2(100) := 'http://localhost:3000';

    --
    -- Helper: haal PDF service URL op uit icca_app_config
    --
    function f_get_pdf_service_url return varchar2 is
        l_pdf_service_url icca_app_config.config_value%type;
    begin
        select config_value
        into   l_pdf_service_url
        from   icca_app_config
        where  config_key = c_config_key_pdf_url
        and    active_ind = 'Y';

        return nvl(l_pdf_service_url, c_default_pdf_url);
    exception
        when no_data_found then
            return c_default_pdf_url;
    end f_get_pdf_service_url;

    --
    -- Helper: Formatteer datum kort (bijv. "5-jan-24")
    --
    function f_format_date_short (
        p_date in date
    ) return varchar2 is
    begin
        return to_char(p_date, 'DD-mon-YY', 'NLS_DATE_LANGUAGE=DUTCH');
    end f_format_date_short;

    --
    -- Helper: Formatteer datum lang (bijv. "10 februari 2025")
    --
    function f_format_date_long (
        p_date in date
    ) return varchar2 is
    begin
        return to_char(p_date, 'DD month YYYY', 'NLS_DATE_LANGUAGE=DUTCH');
    end f_format_date_long;

    --
    -- Helper: Formatteer datum standaard (bijv. "2 januari 2025")
    --
    function f_format_date (
        p_date in date
    ) return varchar2 is
    begin
        return to_char(p_date, 'DD month YYYY', 'NLS_DATE_LANGUAGE=DUTCH');
    end f_format_date;

    --
    -- Helper: Formatteer tijd
    --
    function f_format_time (
        p_date in date
    ) return varchar2 is
    begin
        return to_char(p_date, 'HH24:MI');
    end f_format_time;

    --
    -- 1. Audit Info
    --
    function f_get_audit_info (
        p_adt_id in number
    ) return json_object_t is
        cursor c_documents (
            b_doc_id in number
        ) is
        select doc.file_url
            from icca_documents doc
            where doc.id = b_doc_id;
            
        l_obj              json_object_t := json_object_t();
        l_audit_rec        icca_audits%rowtype;
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

        -- Haal uitvoerder op
        begin
            select pfr.first_name || ' ' || pfr.last_name
                into l_performer_name
                from icca_adt_forms fom
                join icca_performers pfr on pfr.id = fom.pfr_id
                where fom.adt_id = p_adt_id
                fetch first 1 row only;
        exception
            when others then
                l_performer_name := 'Onbekend';
        end;

        -- Haal aanwezige klant op
        begin
            select listagg(apt.name, ', ') within group (order by apt.name)
                into l_present_client
                from icca_adt_present_clients apt
                where apt.adt_id = p_adt_id;
        exception
            when others then
                l_present_client := '';
        end;

        -- Haal client logo op
        open c_documents(l_client_rec.logo_id);
        fetch c_documents into l_client_logo_url;
        close c_documents;

        -- Build JSON object met ICCA_RAPPORT structuur
        l_obj.put('rapport_titel', 'Rapportage ' || l_audit_rec.type || '-IMPO Kwaliteitsmeting');
        l_obj.put('audit_type', l_audit_rec.type);
        -- PDF filename: audit_code.klant_naam.locatie_naam
        l_obj.put(
            'pdf_filename',
            l_audit_rec.code
            || '.'
            || l_client_rec.company_name
            || '.'
            || nvl(l_location_rec.name, 'Onbekend')
            || '.pdf'
        );
        l_obj.put('organisatie', l_client_rec.company_name);
        l_obj.put('ter_attentie_van', nvl(l_location_rec.contact_person, l_client_rec.contact_person));
        l_obj.put('project', nvl(l_location_rec.name, ''));
        l_obj.put('rapportnummer', l_audit_rec.code);
        l_obj.put('datum', f_format_date(l_audit_rec.last_control_date));
        l_obj.put('tijdstip_controle', f_format_time(l_audit_rec.last_control_date));
        --   l_obj.put('extra_info', nvl(l_audit_rec.remark, '-'));
        l_obj.put('controle_uitgevoerd_door', l_performer_name);
        l_obj.put('aanwezig_leverancier', nvl(l_present_client, 'n.v.t.'));
        l_obj.put('controle_datum_lang', f_format_date_long(l_audit_rec.last_control_date));
        l_obj.put('locatie_naam', nvl(l_location_rec.name, ''));
        l_obj.put('locatie_adres', nvl(l_location_rec.street_name, l_client_rec.street_name));
        l_obj.put('locatie_plaats', nvl(l_location_rec.city, l_client_rec.city));

        -- Client logo URL
        if l_client_rec.logo_id is not null and l_client_logo_url is not null then
            l_obj.put('client_logo_url', f_get_pdf_service_url || l_client_logo_url);
        else
            l_obj.put('client_logo_url', '');
        end if;

        return l_obj;
    exception
    when no_data_found then
        return json_object_t();
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
                        when res.is_sufficient = 'Y' then 'Voldoende'
                        else 'Onvoldoende'
                    end as beoordeling
                from icca_adt_results res
                join icca_categories cat on cat.id = res.cat_id
                where res.adt_id = p_adt_id
                order by cat.name
        ) loop
            l_obj := json_object_t();
            l_obj.put('categorie_naam', r.categorie_naam);
            l_obj.put('tel_element', r.tel_element);
            l_obj.put('goedkeurgrens', r.goedkeurgrens);
            l_obj.put('aantal_behaalde_fouten', r.aantal_behaalde_fouten);
            l_obj.put('cijfer', round(r.cijfer, 2));
            l_obj.put('beoordeling', r.beoordeling);
            l_arr.append(l_obj);
        end loop;
        return l_arr;
    end f_get_categories;

    --
    -- 3. Historisch Verloop (laatste 8 audits voor deze locatie)
    --
    function f_get_historisch_verloop (
    p_adt_id in number
    ) return json_array_t is
    l_arr    json_array_t := json_array_t();
    l_obj    json_object_t;
    l_cln_id number;
    begin
    -- Haal locatie ID op
    select cln_id
        into l_cln_id
        from icca_audits
        where id = p_adt_id;

    -- Haal laatste 6 audits op voor deze locatie
    for r in (
        select *
            from (
            select adt.last_control_date,
                    adt.code,
                    (select avg(score) from icca_adt_results where adt_id = adt.id) as gem_cijfer
                from icca_audits adt
                where adt.cln_id = l_cln_id
                and adt.audit_completed = 'Y'
                and adt.last_control_date <= (
                    select last_control_date from icca_audits where id = p_adt_id
                )
                order by adt.last_control_date desc
        )
            where rownum <= 6
            order by last_control_date asc
    ) loop
        l_obj := json_object_t();
        l_obj.put('datum', f_format_date_short(r.last_control_date));
        l_obj.put('auditcode', r.code);
        l_obj.put('cijfer', round(r.gem_cijfer, 2));
        l_arr.append(l_obj);
    end loop;
    return l_arr;
    end f_get_historisch_verloop;

    --
    -- 4. Foutsoorten (met type: dagelijks/cumulatief/divers)
    -- Toont ALLE error types, ook met 0 fouten
    --
    function f_get_foutsoorten (
    p_adt_id in number
    ) return json_array_t is
    l_arr json_array_t := json_array_t();
    l_obj json_object_t;
    l_aantal number;
    
    -- Type bepaling op basis van error type naam
    function f_get_type(p_naam in varchar2) return varchar2 is
        l_naam varchar2(200) := lower(p_naam);
    begin
        -- Dagelijks (geel): Niet gehecht vuil
        if l_naam like 'niet gehecht vuil%' then
            return 'dagelijks';
        -- Cumulatief (blauw): Aanslag, Dicht stof, Gehecht vuil
        elsif l_naam like 'aanslag%' 
            or l_naam like 'dicht stof%'
            or l_naam like 'gehecht vuil%' then
            return 'cumulatief';
        -- Divers (bruin): Niet aangevuld, Niet geleegd, Spinrag
        else
            return 'divers';
        end if;
    end f_get_type;
    
    -- Procedure om een foutsoort toe te voegen
    procedure add_foutsoort(p_naam in varchar2) is
    begin
        -- Haal aantal fouten op voor deze error type
        select nvl(sum(err.error_count), 0)
            into l_aantal
            from icca_fom_errors err
            join icca_adt_forms fom on fom.id = err.fom_id
            join icca_error_types ete on ete.id = err.ete_id
            where fom.adt_id = p_adt_id
            and lower(ete.name) = lower(p_naam)
            -- and (err.added_default_ete_id is null and err.added_default_epe_id is null)
            ;
        
        l_obj := json_object_t();
        -- Split de naam in 4 lijnen
        l_obj.put('lijn1', substr(p_naam, 1, instr(p_naam || ' ', ' ') - 1));
        l_obj.put('lijn2', 
            case 
                when instr(p_naam, ' ') > 0 then
                substr(p_naam, instr(p_naam, ' ') + 1, 
                            nvl(nullif(instr(p_naam, ' ', 1, 2), 0), length(p_naam) + 1) 
                            - instr(p_naam, ' ') - 1)
                else ''
            end
        );
        l_obj.put('lijn3', 
            case 
                when instr(p_naam, ' ', 1, 2) > 0 then
                substr(p_naam, instr(p_naam, ' ', 1, 2) + 1,
                            nvl(nullif(instr(p_naam, ' ', 1, 3), 0), length(p_naam) + 1) 
                            - instr(p_naam, ' ', 1, 2) - 1)
                else ''
            end
        );
        l_obj.put('lijn4', 
            case 
                when instr(p_naam, ' ', 1, 3) > 0 then
                substr(p_naam, instr(p_naam, ' ', 1, 3) + 1)
                else ''
            end
        );
        l_obj.put('aantal', l_aantal);
        l_obj.put('type', f_get_type(p_naam));
        l_arr.append(l_obj);
    end add_foutsoort;
    
    begin
    -- Vaste volgorde: Dagelijks (geel) -> Cumulatief (blauw) -> Divers (bruin)
    -- 1-2: Dagelijks
    add_foutsoort('Niet gehecht vuil licht stof');
    add_foutsoort('Niet gehecht vuil methode');
    -- 3-6: Cumulatief
    add_foutsoort('Aanslag');
    add_foutsoort('Dicht stof');
    add_foutsoort('Gehecht vuil methode');
    add_foutsoort('Gehecht vuil vlek vingertast');
    -- 7-9: Divers
    add_foutsoort('Niet aangevuld');
    add_foutsoort('Niet geleegd');
    add_foutsoort('Spinrag');
    
    return l_arr;
    end f_get_foutsoorten;

    --
    -- 5. Max Fouten (hoogste aantal in foutsoorten)
    --
    function f_get_max_fouten (
    p_adt_id in number
    ) return number is
    l_max number := 0;
    begin
    select nvl(max(sum(err.error_count)), 0)
        into l_max
        from icca_fom_errors err
        join icca_adt_forms fom on fom.id = err.fom_id
        join icca_error_types ete on ete.id = err.ete_id
        where fom.adt_id = p_adt_id
        -- and (err.added_default_ete_id is null and err.added_default_epe_id is null)
        group by ete.id;
    return l_max;
    exception
    when no_data_found then
        return 0;
    end f_get_max_fouten;

    --
    -- 6. Verhouding (percentages per fout categorie)
    -- Berekent op basis van error type naam (zelfde logica als f_get_foutsoorten)
    --
    function f_get_verhouding (
        p_adt_id in number
    ) return json_object_t is
        l_obj          json_object_t := json_object_t();
        l_total        number := 0;
        l_dagelijks    number := 0;
        l_cumulatief   number := 0;
        l_divers       number := 0;
    begin
        -- Totaal aantal fouten
        select nvl(sum(err.error_count), 0)
            into l_total
            from icca_fom_errors err
            join icca_adt_forms fom on fom.id = err.fom_id
            where fom.adt_id = p_adt_id
            -- and (err.added_default_ete_id is null and err.added_default_epe_id is null)
            ;

        if l_total > 0 then
            -- Per error type naam (zelfde logica als f_get_foutsoorten)
            for r in (
                select ete.name as error_type_naam,
                        sum(err.error_count) as aantal
                    from icca_fom_errors err
                    join icca_adt_forms fom on fom.id = err.fom_id
                    join icca_error_types ete on ete.id = err.ete_id
                    where fom.adt_id = p_adt_id
                    -- and (err.added_default_ete_id is null and err.added_default_epe_id is null)
                    group by ete.name
        ) loop
            -- Dagelijks: Niet gehecht vuil
            if lower(r.error_type_naam) like 'niet gehecht vuil%' then
                l_dagelijks := l_dagelijks + r.aantal;
            -- Cumulatief: Aanslag, Dicht stof, Gehecht vuil
            elsif lower(r.error_type_naam) like 'aanslag%' 
                or lower(r.error_type_naam) like 'dicht stof%'
                or lower(r.error_type_naam) like 'gehecht vuil%' then
                l_cumulatief := l_cumulatief + r.aantal;
            -- Divers: rest
            else
                l_divers := l_divers + r.aantal;
            end if;
        end loop;
    end if;

    l_obj.put('dagelijkse_pct', 
        case when l_total > 0 then round((l_dagelijks / l_total) * 100, 1) else 0 end);
    l_obj.put('cumulatief_pct', 
        case when l_total > 0 then round((l_cumulatief / l_total) * 100, 1) else 0 end);
    l_obj.put('diverse_pct', 
        case when l_total > 0 then round((l_divers / l_total) * 100, 1) else 0 end);

    return l_obj;
    end f_get_verhouding;

    --
    -- 7. Ruimte Opmerkingen (fouten per ruimte)
    --
    function f_get_ruimte_opmerkingen (
        p_adt_id in number
    ) return json_array_t is
        l_arr       json_array_t := json_array_t();
        l_obj       json_object_t;
        l_foto_nr   number := 0;
    begin
        for r in (
            select case
                        when fom.migrated_data = 'Y' then fom.migrated_area_code
                        else flr.name || '-' || ara.abbreviation || '.' || fom.area_number
                    end as ruimte_nr,
                    cat.name as categorie,
                    epe.name as element,
                    ete.name as vuilsoort,
                    err.log_book_remark as opmerking,
                    err.error_count as aantal_fouten,
                    err.log_book_image_id as foto_id
                from icca_adt_forms fom
                left join icca_fom_errors err on fom.id = err.fom_id
                left join icca_floors flr on fom.flr_id = flr.id
                left join icca_areas ara on fom.ara_id = ara.id
                left join icca_categories cat on fom.cat_id = cat.id
                left join icca_elementtypes epe on epe.id = err.epe_id
                left join icca_error_types ete on ete.id = err.ete_id
                where fom.adt_id = p_adt_id
                -- and (err.added_default_ete_id is null and err.added_default_epe_id is null)
                order by epe.name nulls last, flr.name, ara.abbreviation, fom.area_number
        ) loop
            -- Foto nummer alleen verhogen als er een foto is
            if r.foto_id is not null then
                l_foto_nr := l_foto_nr + 1;
            end if;
            
            l_obj := json_object_t();
            l_obj.put('ruimte_nr', r.ruimte_nr);
            l_obj.put('categorie', r.categorie);
            l_obj.put('element', r.element);
            l_obj.put('vuilsoort', r.vuilsoort);
            l_obj.put('opmerking', nvl(r.opmerking, ''));
            l_obj.put('aantal_fouten', r.aantal_fouten);
            l_obj.put('foto_nr', case when r.foto_id is not null then to_char(l_foto_nr) else '' end);
            l_arr.append(l_obj);
        end loop;
        return l_arr;
    end f_get_ruimte_opmerkingen;

    --
    -- 8. Element Fotos (logboek fotos met nummer)
    --
    function f_get_element_fotos (
        p_adt_id in number
    ) return json_array_t is
        l_arr          json_array_t := json_array_t();
        l_obj          json_object_t;
        l_count        number := 0;
        l_file_url     varchar2(4000);
        l_base64_data  clob;
    begin
        -- Zelfde volgorde als ruimte_opmerkingen zodat foto_nr matcht
        for r in (
            select err.log_book_image_id as image_id
                from icca_fom_errors err
                join icca_adt_forms fom on fom.id = err.fom_id
                join icca_floors flr on fom.flr_id = flr.id
                join icca_areas ara on fom.ara_id = ara.id
                left join icca_elementtypes epe on epe.id = err.epe_id  -- TOEVOEGEN
                where fom.adt_id = p_adt_id
                and err.log_book_image_id is not null
                order by epe.name nulls last, flr.name, ara.abbreviation, fom.area_number  -- AANPASSEN
        ) loop
            begin
                -- Get file URL from database
                select doc.file_url
                    into l_file_url
                    from icca_documents doc
                    where doc.id = r.image_id;
                    
                if l_file_url is not null then
                    l_base64_data := icca_file_upload.f_get_image_base64(l_file_url);

                    if l_base64_data is not null then  -- Check direct op null
                    l_count := l_count + 1;
                    l_obj := json_object_t();
                    l_obj.put('foto_nummer', l_count);
                    l_obj.put('base64_data', l_base64_data);
                    l_arr.append(l_obj);
                    end if;
                end if;
            exception
                when others then
                    apex_debug.error('Error processing image ' || r.image_id || ': ' || sqlerrm);
                    null;  -- Skip on error
            end;
        end loop;
        return l_arr;
    end f_get_element_fotos;

    --
    -- 9. Technische Aspecten Fotos
    --
    function f_get_technische_aspecten_fotos (
        p_adt_id in number
    ) return json_array_t is
        l_arr          json_array_t := json_array_t();
        l_obj          json_object_t;
        l_file_url     varchar2(4000);
        l_base64_data  clob;
    begin
        for r in (
            select distinct 
                    err.technical_aspects_image_id as image_id,
                    case
                        when fom.migrated_data = 'Y' then fom.migrated_area_code
                        else flr.name || '-' || ara.abbreviation || '.' || fom.area_number
                    end || ': ' || err.technical_aspects_remark as beschrijving
                from icca_fom_errors err
                join icca_adt_forms fom on fom.id = err.fom_id
                join icca_floors flr on fom.flr_id = flr.id
                join icca_areas ara on fom.ara_id = ara.id
                where fom.adt_id = p_adt_id
                and err.technical_aspects_image_id is not null
            union all
            select  nvl(img2.doc_id, 66023 )     as image_id
            ,       fom.areacode ||': ' || rmk.remarktext  as beschrijving
            from    auditremarks2 rmk
            join    audits2 adt on adt.id = rmk.auditid
            join    forms2 fom on fom.id = rmk.formid
            join    images2 img2 on img2.imageid = remarkimage
            where   adt.adt_id = p_adt_id
            -- and     img2.doc_id is not null
            union all
            select  nvl(fmr.remark_image_id, 66023 )    as image_id
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
            begin
                -- Get file URL from database
                select doc.file_url
                    into l_file_url
                    from icca_documents doc
                    where doc.id = r.image_id;
                    
                if l_file_url is not null then
                    l_base64_data := icca_file_upload.f_get_image_base64(l_file_url);
                    
                    if l_base64_data is not null then
                    l_obj := json_object_t();
                    l_obj.put('base64_data', l_base64_data);
                    l_obj.put('beschrijving', nvl(r.beschrijving, ''));
                    l_arr.append(l_obj);
                    end if;
                end if;
            exception
                when others then
                    apex_debug.error('Error processing image ' || r.image_id || ': ' || sqlerrm);
                    null;  -- Skip on error
            end;
        end loop;
        return l_arr;
    end f_get_technische_aspecten_fotos;

    --
    -- 10. Algemene Opmerkingen (ruimte opmerkingen)
    --
    function f_get_algemene_opmerkingen (
        p_adt_id in number
    ) return json_array_t is
        l_arr json_array_t := json_array_t();
        l_obj json_object_t;
    begin
        for r in (
            select case
                        when fom.migrated_data = 'Y' then fom.migrated_area_code
                        else flr.name || '-' || ara.abbreviation || '.' || fom.area_number
                    end as ruimtenummer,
                    fom.remark as opmerkingen
                from icca_adt_forms fom
                join icca_floors flr on fom.flr_id = flr.id
                join icca_areas ara on fom.ara_id = ara.id
                where fom.adt_id = p_adt_id
                and fom.remark is not null
                order by flr.name, ara.abbreviation, fom.area_number
        ) loop
            l_obj := json_object_t();
            l_obj.put('ruimtenummer', r.ruimtenummer);
            l_obj.put('opmerkingen', r.opmerkingen);
            l_arr.append(l_obj);
        end loop;
        return l_arr;
    end f_get_algemene_opmerkingen;

    --
    -- 11. Overige Hygiene Aspecten (KPI elements)
    --
    function f_get_overige_hygiene_aspecten (
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
            l_obj.put('algemeen', r.algemeen);
            -- Status omzetten naar volledige tekst
            l_obj.put('status', 
                case r.status
                    when 'O' then 'Opmerking'
                    when 'V' then 'Voldoende'
                    when 'G' then 'Goed'
                    when 'N' then 'N.v.t.'
                    else 'N.v.t.'
                end
            );
            l_obj.put('opmerkingen', nvl(r.opmerkingen, ''));
            l_arr.append(l_obj);
        end loop;
        return l_arr;
    end f_get_overige_hygiene_aspecten;

    --
    -- Main: Generate Full JSON voor ICCA_RAPPORT
    --
    function f_get_main_json (
        p_adt_id in number
    ) return clob is
        l_root        json_object_t;
        l_data        json_object_t;
        l_json_clob   CLOB;
        l_pretty_json CLOB;
    begin
        l_root := json_object_t();
        l_data := json_object_t();
        
        l_root.put('template_name', 'BLINCK_RAPPORT');
            
        -- Build data object
        l_data.put('audit_info', f_get_audit_info(p_adt_id));
        l_data.put('categories', f_get_categories(p_adt_id));
        l_data.put('historisch_verloop', f_get_historisch_verloop(p_adt_id));
        l_data.put('foutsoorten', f_get_foutsoorten(p_adt_id));
        l_data.put('max_fouten', f_get_max_fouten(p_adt_id));
        l_data.put('verhouding', f_get_verhouding(p_adt_id));
        l_data.put('ruimte_opmerkingen', f_get_ruimte_opmerkingen(p_adt_id));
        l_data.put('element_fotos', f_get_element_fotos(p_adt_id));
        l_data.put('technische_aspecten_fotos', f_get_technische_aspecten_fotos(p_adt_id));
        l_data.put('algemene_opmerkingen', f_get_algemene_opmerkingen(p_adt_id));
        l_data.put('overige_hygiene_aspecten', f_get_overige_hygiene_aspecten(p_adt_id));
        
        l_root.put('data', l_data);
        
        -- Convert to CLOB and prettify
        l_json_clob := l_root.to_clob();
        
        select json_serialize(l_json_clob returning clob pretty)
        into l_pretty_json
        from dual;
        
        dbms_output.put_line('=== JSON DATA (BEAUTIFIED) ===');
        dbms_output.put_line('Length: ' || dbms_lob.getlength(l_pretty_json));
        dbms_output.put_line('---');
        dbms_output.put_line(substr(l_pretty_json, 1, 32000));
        
        return l_root.to_clob();
    end f_get_main_json;

end icca_pdf_blinck_data;
/
