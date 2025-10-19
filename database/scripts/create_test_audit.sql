set serveroutput on;
declare
    -- ========================================
    -- CONFIGURATIE VARIABELEN - PAS HIER AAN
    -- ========================================
    
    -- AANTAL AUDITS
    l_to_create_audit_cnt   constant number         := 10;                   -- HOEVEEL AUDITS AANMAKEN
    
    -- Client en locatie
    v_cnt_id                constant number         := 1;                    -- Client ID
    v_location_name         constant varchar2(255)  := 'Hoofdkantoor';       -- Locatie naam (of NULL voor eerste locatie)
    
    -- Performer(s) - kies één optie:
    v_performer_first_name  constant varchar2(100)  := 'Rewiesh';            -- Voornaam performer (enkele performer)
    v_performer_last_name   constant varchar2(100)  := null;                 -- Achternaam (optioneel)
    -- OF gebruik colon-separated IDs voor meerdere performers:
    v_performer_ids         constant varchar2(4000) := null;                 -- Bijv: '5:12:23' (laat NULL voor single performer)
    
    -- Audit details
    v_audit_type            constant varchar2(255)  := 'Reguliere Inspectie'; -- Type audit
    v_audit_date            constant date           := sysdate;               -- Start datum
    v_interval_days         constant number         := 7;                     -- Interval tussen audits (dagen)
    v_last_control_date     constant date           := null;                  -- Laatste controle datum (optioneel)
    v_active                constant varchar2(1)    := 'Y';                   -- Active Y/N
    v_activate              constant varchar2(1)    := 'Y';                   -- Activate Y/N
    v_audit_completed       constant varchar2(1)    := 'N';                   -- Completed Y/N
    
    -- ========================================
    -- INTERNE VARIABELEN - NIET AANPASSEN
    -- ========================================
    v_adt_id                number;
    v_pfr_id                number;
    v_cln_id                number;
    v_code                  varchar2(50);
    v_performer_count       number := 0;
    v_current_audit_date    date;
    
begin
    --
    dbms_output.put_line('========================================');
    dbms_output.put_line('START: Aanmaken van ' || l_to_create_audit_cnt || ' audits');
    dbms_output.put_line('========================================');
    dbms_output.put_line('');
    
    -- 1. Haal performer 1x op (buiten loop voor efficiency)
    if v_performer_ids is null then
        begin
            select  id
            into    v_pfr_id
            from    icca_performers
            where   upper(first_name) = upper(v_performer_first_name)
            and     (v_performer_last_name is null or upper(last_name) = upper(v_performer_last_name))
            order by id desc
            fetch first 1 rows only;
            
            dbms_output.put_line('✓ Performer gevonden: ID=' || v_pfr_id);
        exception
            when no_data_found then
                raise_application_error(-20001, 'Performer niet gevonden: ' || v_performer_first_name || ' ' || v_performer_last_name);
        end;
    end if;
    
    --
    -- 2. Haal locatie 1x op (buiten loop voor efficiency)
    begin
        if v_location_name is not null then
            select  id
            into    v_cln_id
            from    icca_client_locations
            where   cnt_id = v_cnt_id
            and     upper(name) = upper(v_location_name)
            and     active = 'Y'
            fetch first 1 rows only;
        else
            select  id
            into    v_cln_id
            from    icca_client_locations
            where   cnt_id = 1 -- v_cnt_id
            -- and     active = 'Y'
            order by id
            fetch first 1 rows only;
        end if;
        
        dbms_output.put_line('✓ Locatie gevonden: ID=' || v_cln_id);
    exception
        when no_data_found then
            raise_application_error(-20002, 'Geen actieve locatie gevonden voor client ID=' || v_cnt_id);
    end;
    
    dbms_output.put_line('');
    
    --
    -- 3. LOOP: Maak audits aan
    for i in 1..l_to_create_audit_cnt loop
        
        dbms_output.put_line('--- Audit ' || i || ' van ' || l_to_create_audit_cnt || ' ---');
        
        v_performer_count := 0;
        
        -- Bereken audit datum (elke audit krijgt interval_days extra)
        v_current_audit_date := v_audit_date + ((i - 1) * v_interval_days);
        
        -- Genereer audit code
        v_code := 'ADT-' || to_char(icca_adt_code_seq.nextval);
        dbms_output.put_line('  Code: ' || v_code);
        
        -- Maak audit aan
        insert into icca_audits (
            pfr_id,
            code,
            audit_date,
            last_control_date,
            active,
            cnt_id,
            cln_id,
            type,
            activate,
            audit_completed,
            created_by
        ) values (
            case when v_performer_ids is null then v_pfr_id else null end,
            v_code,
            v_current_audit_date,
            v_last_control_date,
            v_active,
            v_cnt_id,
            v_cln_id,
            v_audit_type,
            v_activate,
            v_audit_completed,
            user
        )
        returning id into v_adt_id;
        
        dbms_output.put_line('  ✓ Audit ID: ' || v_adt_id);
        dbms_output.put_line('  ✓ Datum: ' || to_char(v_current_audit_date, 'DD-MON-YYYY'));
        
        -- Assign performer(s)
        if v_performer_ids is not null then
            -- Meerdere performers
            for pfr in (
                select  trim(regexp_substr(v_performer_ids, '[^:]+', 1, level)) as pfr_id
                from    dual
                connect by level <= regexp_count(v_performer_ids, ':') + 1
            ) loop
                if pfr.pfr_id is not null then
                    insert into icca_adt_performers (adt_id, pfr_id)
                    values (v_adt_id, pfr.pfr_id);
                    
                    v_performer_count := v_performer_count + 1;
                end if;
            end loop;
            
            dbms_output.put_line('  ✓ ' || v_performer_count || ' performer(s) toegewezen');
        else
            -- Enkele performer
            insert into icca_adt_performers (adt_id, pfr_id)
            values (v_adt_id, v_pfr_id);
            
            dbms_output.put_line('  ✓ Performer toegewezen');
        end if;
        
        dbms_output.put_line('');
        
    end loop;
    
    --
    -- 4. Commit alles
    commit;
    
    dbms_output.put_line('========================================');
    dbms_output.put_line('SUCCESS!');
    dbms_output.put_line('========================================');
    dbms_output.put_line('Totaal audits aangemaakt: ' || l_to_create_audit_cnt);
    dbms_output.put_line('Client ID               : ' || v_cnt_id);
    dbms_output.put_line('Location ID             : ' || v_cln_id);
    if v_performer_ids is not null then
        dbms_output.put_line('Performers per audit    : Meerdere (IDs: ' || v_performer_ids || ')');
    else
        dbms_output.put_line('Performer ID            : ' || v_pfr_id);
    end if;
    dbms_output.put_line('Type                    : ' || v_audit_type);
    dbms_output.put_line('Start datum             : ' || to_char(v_audit_date, 'DD-MON-YYYY'));
    dbms_output.put_line('Interval                : ' || v_interval_days || ' dagen');
    dbms_output.put_line('========================================');
    
exception
    when others then
        rollback;
        dbms_output.put_line('');
        dbms_output.put_line('========================================');
        dbms_output.put_line('ERROR!');
        dbms_output.put_line('========================================');
        dbms_output.put_line('Error: ' || sqlerrm);
        dbms_output.put_line('========================================');
        raise;
end;
/