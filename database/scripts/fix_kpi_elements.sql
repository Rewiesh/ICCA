set serveroutput on;
set define off;
declare
    -- Types voor collections
    type t_ant_id_tab     is table of icca_adt_kpi_elements.id%type;
    type t_kcn_id_tab     is table of icca_adt_kpi_elements.kcn_id%type;
    type t_ket_id_tab     is table of icca_adt_kpi_elements.ket_id%type;
    type t_cnt_id_tab     is table of icca_clients.id%type;
    type t_adt_id_tab     is table of icca_audits.id%type;
    
    -- Collections
    l_ant_ids       t_ant_id_tab;
    l_old_kcn_ids   t_kcn_id_tab;
    l_ket_ids       t_ket_id_tab;
    l_cnt_ids       t_cnt_id_tab;
    l_adt_ids       t_adt_id_tab;
    
    -- Collections voor update
    l_update_ant_ids    t_ant_id_tab := t_ant_id_tab();
    l_update_kcn_ids    t_kcn_id_tab := t_kcn_id_tab();
    
    -- Collections voor insert
    l_insert_ket_ids    t_ket_id_tab := t_ket_id_tab();
    l_insert_cnt_ids    t_cnt_id_tab := t_cnt_id_tab();
    
    -- Lokale variabele voor nieuwe KCN_ID
    l_new_kcn_id        icca_ket_clients.id%type;
    
    -- Statistieken
    l_start_time        timestamp := systimestamp;
    l_records_checked   number := 0;
    l_records_updated   number := 0;
    l_records_skipped   number := 0;
    l_records_no_kcn    number := 0;
    l_records_inserted  number := 0;
    l_duplicates_found  number := 0;
    l_duplicates_deleted number := 0;
    
    -- Batch size
    c_batch_size        constant number := 15000;
    c_username          constant varchar2(50) := 'MIGRATION_SCRIPT';
    
begin
    dbms_output.put_line('╔════════════════════════════════════════════════════╗');
    dbms_output.put_line('║   KCN_ID Correctie & Duplicate Cleanup Script     ║');
    dbms_output.put_line('╚════════════════════════════════════════════════════╝');
    dbms_output.put_line('Starttijd: ' || to_char(l_start_time, 'DD-MM-YYYY HH24:MI:SS'));
    dbms_output.put_line('Batch size: ' || c_batch_size);
    dbms_output.put_line('');
    
    -- ========================================
    -- STAP 1: DUPLICATES DETECTIE & CLEANUP
    -- ========================================
    dbms_output.put_line('┌─ STAP 1: Duplicates Detectie ─────────────────────┐');
    
    -- Tel duplicates
    select  count(*)
    into    l_duplicates_found
    from    (
        select  adt_id, ket_id, cnt_id, count(*) as cnt
        from    icca_adt_kpi_elements ant
        join    icca_audits adt on ant.adt_id = adt.id
        join    icca_clients cnt on adt.cnt_id = cnt.id
        --where adt.code = 10450
        group by adt_id, ket_id, cnt_id
        having count(*) > 1
    );
    
    dbms_output.put_line('  Gevonden: ' || l_duplicates_found || ' duplicate combinaties');
    
    if l_duplicates_found > 0 then
        dbms_output.put_line('  Bezig met opschonen...');
        
        -- Verwijder duplicates, behoud alleen de EERSTE record (laagste ID)
        delete from icca_adt_kpi_elements ant
        where ant.id in (
            select ant2.id
            from icca_adt_kpi_elements ant2
            where (ant2.adt_id, ant2.ket_id) in (
                select adt_id, ket_id
                from icca_adt_kpi_elements
                group by adt_id, ket_id
                having count(*) > 1
            )
            and ant2.id not in (
                -- Behoud het EERSTE record (laagste ID) per combinatie
                select min(id)
                from icca_adt_kpi_elements
                group by adt_id, ket_id
            )
        );
        
        l_duplicates_deleted := sql%rowcount;
        commit;
        
        dbms_output.put_line('  ✓ Duplicates verwijderd: ' || l_duplicates_deleted || ' records');
    else
        dbms_output.put_line('  ✓ Geen duplicates gevonden');
    end if;
    
    dbms_output.put_line('└────────────────────────────────────────────────────┘');
    dbms_output.put_line('');
    
    -- ========================================
    -- STAP 2: DATA OPHALEN
    -- ========================================
    dbms_output.put_line('┌─ STAP 2: Data Ophalen ────────────────────────────┐');
    
    -- Bulk collect van alle te controleren records (GEEN WHERE filter meer)
    select  ant.id
    ,       ant.kcn_id
    ,       ant.ket_id
    ,       cnt.id
    ,       adt.id
    bulk collect into
            l_ant_ids
    ,       l_old_kcn_ids
    ,       l_ket_ids
    ,       l_cnt_ids
    ,       l_adt_ids
    from    icca_adt_kpi_elements ant
    join    icca_audits adt on ant.adt_id = adt.id
    join    icca_clients cnt on adt.cnt_id = cnt.id
    --where adt.code = 10450
    fetch first c_batch_size rows only;
    
    l_records_checked := l_ant_ids.count;
    dbms_output.put_line('  Records opgehaald: ' || l_records_checked);
    
    if l_records_checked = 0 then
        dbms_output.put_line('  ⚠ Geen records gevonden - script stopt');
        return;
    end if;
    
    dbms_output.put_line('└────────────────────────────────────────────────────┘');
    dbms_output.put_line('');
    
    -- ========================================
    -- STAP 3: KCN RECORDS VERWERKEN
    -- ========================================
    dbms_output.put_line('┌─ STAP 3: KCN Records Controleren ─────────────────┐');
    
    -- Loop door alle records
    for i in 1..l_ant_ids.count
    loop
        -- Reset lokale variabele
        l_new_kcn_id := null;
        
        -- Haal de correcte kcn_id op
        begin
            select  id
            into    l_new_kcn_id
            from    icca_ket_clients
            where   cnt_id = l_cnt_ids(i)
            and     ket_id = l_ket_ids(i);
            
            -- Vergelijk oude en nieuwe kcn_id
            if l_old_kcn_ids(i) is null then
                -- KCN_ID is NULL, moet gevuld worden
                l_update_ant_ids.extend;
                l_update_kcn_ids.extend;
                l_update_ant_ids(l_update_ant_ids.count) := l_ant_ids(i);
                l_update_kcn_ids(l_update_kcn_ids.count) := l_new_kcn_id;
                
                dbms_output.put_line('  ○ Record ' || l_ant_ids(i) || ': KCN_ID NULL => ' || l_new_kcn_id);
                
            elsif l_new_kcn_id != l_old_kcn_ids(i) then
                -- KCN_ID is FOUT
                l_update_ant_ids.extend;
                l_update_kcn_ids.extend;
                l_update_ant_ids(l_update_ant_ids.count) := l_ant_ids(i);
                l_update_kcn_ids(l_update_kcn_ids.count) := l_new_kcn_id;
                
                dbms_output.put_line('  ✗ Record ' || l_ant_ids(i) || ': KCN_ID ' || l_old_kcn_ids(i) || ' => ' || l_new_kcn_id || ' (FOUT)');
            else
                -- KCN_ID is correct
                l_records_skipped := l_records_skipped + 1;
            end if;
            
        exception
            when no_data_found then
                -- KCN record bestaat NIET - moet worden aangemaakt
                l_records_no_kcn := l_records_no_kcn + 1;
                
                -- Check of deze combinatie al in de insert lijst staat
                declare
                    l_already_in_list boolean := false;
                begin
                    for j in 1..l_insert_ket_ids.count
                    loop
                        if l_insert_ket_ids(j) = l_ket_ids(i) and l_insert_cnt_ids(j) = l_cnt_ids(i) then
                            l_already_in_list := true;
                            exit;
                        end if;
                    end loop;
                    
                    if not l_already_in_list then
                        l_insert_ket_ids.extend;
                        l_insert_cnt_ids.extend;
                        l_insert_ket_ids(l_insert_ket_ids.count) := l_ket_ids(i);
                        l_insert_cnt_ids(l_insert_cnt_ids.count) := l_cnt_ids(i);
                        
                        dbms_output.put_line('  + NIEUW: KCN aanmaken voor KET_ID ' || l_ket_ids(i) || ', CNT_ID ' || l_cnt_ids(i));
                    end if;
                end;
                
            when too_many_rows then
                l_records_no_kcn := l_records_no_kcn + 1;
                dbms_output.put_line('  ⚠ ERROR: Meerdere KCN gevonden voor ANT_ID ' || l_ant_ids(i) || ' (CNT_ID: ' || l_cnt_ids(i) || ', KET_ID: ' || l_ket_ids(i) || ')');
        end;
    end loop;
    
    dbms_output.put_line('└────────────────────────────────────────────────────┘');
    dbms_output.put_line('');
    
    -- ========================================
    -- STAP 4: NIEUWE KCN RECORDS INVOEGEN
    -- ========================================
    if l_insert_ket_ids.count > 0 then
        dbms_output.put_line('┌─ STAP 4: Nieuwe KCN Records Aanmaken ─────────────┐');
        dbms_output.put_line('  Aantal nieuwe records: ' || l_insert_ket_ids.count);
        
        -- Bulk insert van nieuwe KCN records
        forall i in 1..l_insert_ket_ids.count
            insert into icca_ket_clients (
                ket_id
            ,   cnt_id
            ,   migrated_data
            ,   created_date
            ,   created_by
            )
            values (
                l_insert_ket_ids(i)
            ,   l_insert_cnt_ids(i)
            ,   'Y'  -- Markeer als gemigreerde data
            ,   sysdate
            ,   c_username
            );
        
        l_records_inserted := sql%rowcount;
        commit;
        
        dbms_output.put_line('  ✓ KCN records aangemaakt: ' || l_records_inserted);
        dbms_output.put_line('└────────────────────────────────────────────────────┘');
        dbms_output.put_line('');
        
        -- Nu opnieuw de KCN_IDs ophalen voor de updates
        dbms_output.put_line('┌─ STAP 4b: KCN_IDs Opnieuw Ophalen ────────────────┐');
        
        for i in 1..l_ant_ids.count
        loop
            if l_old_kcn_ids(i) is null then
                begin
                    select  id
                    into    l_new_kcn_id
                    from    icca_ket_clients
                    where   cnt_id = l_cnt_ids(i)
                    and     ket_id = l_ket_ids(i);
                    
                    -- Toevoegen aan update lijst
                    l_update_ant_ids.extend;
                    l_update_kcn_ids.extend;
                    l_update_ant_ids(l_update_ant_ids.count) := l_ant_ids(i);
                    l_update_kcn_ids(l_update_kcn_ids.count) := l_new_kcn_id;
                    
                exception
                    when no_data_found then
                        dbms_output.put_line('  ⚠ Kan KCN nog steeds niet vinden voor ANT_ID ' || l_ant_ids(i));
                end;
            end if;
        end loop;
        
        dbms_output.put_line('  ✓ Gereed');
        dbms_output.put_line('└────────────────────────────────────────────────────┘');
        dbms_output.put_line('');
    end if;
    
    -- ========================================
    -- STAP 5: KCN_ID UPDATES
    -- ========================================
    dbms_output.put_line('┌─ STAP 5: KCN_ID Updates ──────────────────────────┐');
    
    if l_update_ant_ids.count > 0 then
        dbms_output.put_line('  Start bulk update van ' || l_update_ant_ids.count || ' records...');
        
        forall i in 1..l_update_ant_ids.count
            update  icca_adt_kpi_elements
            set     kcn_id = l_update_kcn_ids(i)
            ,       modified_date = sysdate
            ,       modified_by = c_username
            where   id = l_update_ant_ids(i);
        
        l_records_updated := sql%rowcount;
        commit;
        
        dbms_output.put_line('  ✓ Bulk update succesvol: ' || l_records_updated || ' records');
    else
        dbms_output.put_line('  ✓ Geen updates nodig - alle KCN_IDs zijn correct');
    end if;
    
    dbms_output.put_line('└────────────────────────────────────────────────────┘');
    dbms_output.put_line('');
    
    -- ========================================
    -- SAMENVATTING
    -- ========================================
    dbms_output.put_line('╔════════════════════════════════════════════════════╗');
    dbms_output.put_line('║               SAMENVATTING                         ║');
    dbms_output.put_line('╠════════════════════════════════════════════════════╣');
    dbms_output.put_line('║ Duplicates gevonden:    ' || rpad(l_duplicates_found, 25) || '║');
    dbms_output.put_line('║ Duplicates verwijderd:  ' || rpad(l_duplicates_deleted, 25) || '║');
    dbms_output.put_line('║ Records gecontroleerd:  ' || rpad(l_records_checked, 25) || '║');
    dbms_output.put_line('║ KCN records aangemaakt: ' || rpad(l_records_inserted, 25) || '║');
    dbms_output.put_line('║ KCN_IDs geüpdatet:      ' || rpad(l_records_updated, 25) || '║');
    dbms_output.put_line('║ Records correct:        ' || rpad(l_records_skipped, 25) || '║');
--    dbms_output.put_line('║ Verwerktijd:            ' || rpad(round((systimestamp - l_start_time) * 86400, 2) || ' sec', 25) || '║');
    dbms_output.put_line('╚════════════════════════════════════════════════════╝');
    
exception
    when others then
        rollback;
        dbms_output.put_line('');
        dbms_output.put_line('╔════════════════════════════════════════════════════╗');
        dbms_output.put_line('║               ❌ CRITICAL ERROR                    ║');
        dbms_output.put_line('╚════════════════════════════════════════════════════╝');
        dbms_output.put_line('Error: ' || sqlerrm);
--        dbms_output.put_line('Backtrace: ' || dbms_utility.format_error_backtrace);
        dbms_output.put_line('Rollback uitgevoerd');
        raise;
end;
/