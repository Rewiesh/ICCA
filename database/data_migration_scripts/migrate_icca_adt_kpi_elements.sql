set serveroutput on;
declare
    cursor c_get_old_data
    is
        select  ant.idaudit                                     as old_adt_id
        ,       ant.idelement                                   as old_elm_id
        ,       adt.adt_id                                      as new_adt_id
        ,       elm.ket_id                                      as new_ket_id
        ,       null                                            as new_kcn_id
        ,       elm.elementlabel                                as element_label
        ,       trim(sts.ElementStatusValueCode)                as element_value
        ,       ant.elementauditcomment                         as element_comment
        from    elementaudit2        ant
        join    audits2              adt on adt.id = ant.idaudit
        join    element              elm on elm.id = ant.idelement
--        left join elementclient     kcn on kcn.idelement = ant.idelement and kcn.kcn_id is not null
        join    ElementStatusValue  sts on sts.id = ant.elementauditstatus
        where   adt.adt_id is not null
        and     elm.ket_id is not null
         and ant.ant_id is null
        -- and adt.auditcode = '10215'
        ; 
    
    type t_old_data is table of c_get_old_data%rowtype;
    lt_old_data t_old_data;
    ln_ant_id number;
    ln_existing_ant_id number;
    
    ln_total_elements number := 0;
    ln_new_elements number := 0;
    ln_reused_elements number := 0;
    ln_failed_elements number := 0;
    ln_with_kcn_id number := 0;
    ln_without_kcn_id number := 0;
    
    ln_commit_batch constant number := 1000;
    ln_progress_batch constant number := 5000;
    ln_start_time timestamp := systimestamp;
begin
    dbms_output.put_line('========================================');
    dbms_output.put_line('Starting audit KPI elements migration...');
    dbms_output.put_line('========================================');
    
    open    c_get_old_data;
    fetch   c_get_old_data bulk collect into lt_old_data;
    close   c_get_old_data;
    
    dbms_output.put_line('Total records to process: ' || lt_old_data.count);
    dbms_output.put_line('');
    
    for i in 1 .. lt_old_data.count 
    loop
        begin
            ln_ant_id := null;
            ln_existing_ant_id := null;
            
            -- ============================================
            -- AUDIT KPI ELEMENT MIGRATIE (met duplicate check)
            -- ============================================
            
            -- Check of element al gemigreerd is via oude tabel
            begin
                select ant_id 
                into ln_existing_ant_id
                from elementaudit2
                where idelement = lt_old_data(i).old_elm_id
                and idaudit = lt_old_data(i).old_adt_id
                and ant_id is not null;
            exception
                when no_data_found then
                    ln_existing_ant_id := null;
            end;
            
            -- Als nog niet gemigreerd, check op unieke combinatie
            if ln_existing_ant_id is null then
                begin
                    select  id 
                    into    ln_existing_ant_id
                    from    icca_adt_kpi_elements
                    where   adt_id = lt_old_data(i).new_adt_id
                    and     ket_id = lt_old_data(i).new_ket_id
--                    and     nvl(kcn_id, -1) = nvl(lt_old_data(i).new_kcn_id, -1)
                    and     rownum = 1;
                exception
                    when no_data_found then
                        ln_existing_ant_id := null;
                end;
            end if;
            
            -- Element aanmaken of hergebruiken
            if ln_existing_ant_id is not null then
                ln_ant_id := ln_existing_ant_id;
                ln_reused_elements := ln_reused_elements + 1;
            else
                insert into icca_adt_kpi_elements(  kcn_id          
                                                ,   adt_id          
                                                ,   ket_id          
                                                ,   element_label   
                                                ,   element_value   
                                                ,   element_comment 
                                                ,   migrated_data      
                                            ) values (
                                                    lt_old_data(i).new_kcn_id
                                                ,   lt_old_data(i).new_adt_id
                                                ,   lt_old_data(i).new_ket_id
                                                ,   lt_old_data(i).element_label
                                                ,   lt_old_data(i).element_value
                                                ,   lt_old_data(i).element_comment
                                                ,   'Y'
                                                )
                                returning id into ln_ant_id;
                
                ln_new_elements := ln_new_elements + 1;
                
                -- Count kcn_id stats
                if lt_old_data(i).new_kcn_id is not null then
                    ln_with_kcn_id := ln_with_kcn_id + 1;
                else
                    ln_without_kcn_id := ln_without_kcn_id + 1;
                end if;
            end if;
            
            -- Update oude elementaudit tabel (idempotent)
            update  elementaudit2
            set     ant_id = ln_ant_id
            where   idelement = lt_old_data(i).old_elm_id
            and     idaudit = lt_old_data(i).old_adt_id;
            
            ln_total_elements := ln_total_elements + 1;
            
            -- Batch commit
            if mod(ln_total_elements, ln_commit_batch) = 0 then
                commit;
            end if;
            
            -- Progress indicator
            if mod(ln_total_elements, ln_progress_batch) = 0 then
                dbms_output.put_line('Progress: ' || ln_total_elements || ' / ' || lt_old_data.count || 
                                   ' (' || round((ln_total_elements / lt_old_data.count) * 100, 1) || '%)');
            end if;
            
        exception
            when others then
                ln_failed_elements := ln_failed_elements + 1;
                ln_total_elements := ln_total_elements + 1;
                
                -- Log alleen eerste 10 errors
                if ln_failed_elements <= 10 then
                    dbms_output.put_line('✗ Error #' || ln_failed_elements || 
                                       ' - adt_id: ' || lt_old_data(i).old_adt_id || 
                                       ', elm_id: ' || lt_old_data(i).old_elm_id || 
                                       ' - ' || substr(sqlerrm, 1, 200));
                end if;
                
                continue;
        end;
    end loop;
    
    commit;
    
    -- Calculate duration and summary
    declare
        ln_duration interval day to second;
        ln_seconds number;
        ln_not_migrated number;
    begin
        ln_duration := systimestamp - ln_start_time;
        ln_seconds := extract(day from ln_duration) * 86400 + 
                     extract(hour from ln_duration) * 3600 + 
                     extract(minute from ln_duration) * 60 + 
                     extract(second from ln_duration);
        
        dbms_output.put_line('');
        dbms_output.put_line('========================================');
        dbms_output.put_line('AUDIT KPI ELEMENTS MIGRATION SUMMARY');
        dbms_output.put_line('========================================');
        dbms_output.put_line('Total elements processed:       ' || ln_total_elements);
        dbms_output.put_line('  ✓ New elements created:       ' || ln_new_elements);
        dbms_output.put_line('  ✓ Existing elements reused:   ' || ln_reused_elements);
        dbms_output.put_line('  ✗ Failed elements:            ' || ln_failed_elements);
        dbms_output.put_line('');
        dbms_output.put_line('Client element mappings (kcn_id):');
        dbms_output.put_line('  - With kcn_id:                ' || ln_with_kcn_id);
        dbms_output.put_line('  - Without kcn_id (NULL):      ' || ln_without_kcn_id);
        dbms_output.put_line('');
        dbms_output.put_line('Duration:                       ' || round(ln_seconds, 2) || ' seconds');
        if ln_seconds > 0 then
            dbms_output.put_line('Average speed:                  ' || round(ln_total_elements / ln_seconds, 0) || ' records/second');
        end if;
        dbms_output.put_line('========================================');
        
        -- Check for records NOT migrated
        select count(*) into ln_not_migrated 
        from elementaudit2
        where ant_id is null;
        
        if ln_not_migrated > 0 then
            dbms_output.put_line('');
            dbms_output.put_line('⚠ Records NOT migrated: ' || ln_not_migrated);
            dbms_output.put_line('  Possible reasons:');
            dbms_output.put_line('  - Missing adt_id in audits table');
            dbms_output.put_line('  - Missing ket_id in element table');
        else
            dbms_output.put_line('');
            dbms_output.put_line('✓ All records migrated successfully!');
        end if;
    end;
end;
/