set serveroutput on;
declare
    cursor c_get_old_data
    is
        select  ars.idaudit                                         as old_adt_id
        ,       ars.idcategory                                      as old_cat_id
        ,       adt.adt_id                                          as new_adt_id
        ,       cat.cat_id                                          as new_cat_id
        ,       ars.counterelements                                 as counter_elements
        ,       ars.approvelimit                                    as approve_limit
        ,       ars.rating                                          as score
        ,       case when ars.IsSuficient = 1 then 'Y' else 'N' end as is_sufficient
        from    ResultAuditCategory2 ars
        join    audits2              adt on ars.idaudit = adt.id
        join    categories          cat on ars.idcategory = cat.id
        where   adt.adt_id is not null
        and     cat.cat_id is not null
        and ars.ars_id is null
        ;
    
    type t_old_data is table of c_get_old_data%rowtype;
    lt_old_data t_old_data;
    ln_ars_id number;
    ln_existing_ars_id number;
    ln_counter_errors number;
    
    ln_total_results number := 0;
    ln_new_results number := 0;
    ln_reused_results number := 0;
    ln_failed_results number := 0;
    ln_with_errors number := 0;
    
    ln_commit_batch constant number := 500;
    ln_progress_batch constant number := 1000;
    ln_start_time timestamp := systimestamp;
begin
    dbms_output.put_line('========================================');
    dbms_output.put_line('Starting audit results migration...');
    dbms_output.put_line('========================================');
    
    open    c_get_old_data;
    fetch   c_get_old_data bulk collect into lt_old_data;
    close   c_get_old_data;
    
    dbms_output.put_line('Total records to process: ' || lt_old_data.count);
    dbms_output.put_line('');
    
    for i in 1 .. lt_old_data.count 
    loop
        begin
            ln_ars_id := null;
            ln_existing_ars_id := null;
            ln_counter_errors := 0;
            
            -- ============================================
            -- Bereken counter_errors uit icca_fom_errors
            -- ============================================
            begin
                select  nvl(sum(err.error_count), 0)
                into    ln_counter_errors
                from    icca_adt_forms fom
                join    icca_fom_errors err on err.fom_id = fom.id
                where   fom.adt_id = lt_old_data(i).new_adt_id
                and     fom.cat_id = lt_old_data(i).new_cat_id;
            exception
                when no_data_found then
                    ln_counter_errors := 0;
            end;
            
            if ln_counter_errors > 0 then
                ln_with_errors := ln_with_errors + 1;
            end if;
            
            -- ============================================
            -- AUDIT RESULT MIGRATIE (met duplicate check)
            -- ============================================
            
            -- Check of result al gemigreerd is via oude tabel
            begin
                select ars_id 
                into ln_existing_ars_id
                from ResultAuditCategory2
                where idaudit = lt_old_data(i).old_adt_id
                and idcategory = lt_old_data(i).old_cat_id
                and ars_id is not null;
            exception
                when no_data_found then
                    ln_existing_ars_id := null;
            end;
            
            -- Als nog niet gemigreerd, check op unieke combinatie
            if ln_existing_ars_id is null then
                begin
                    select  id 
                    into    ln_existing_ars_id
                    from    icca_adt_results
                    where   adt_id = lt_old_data(i).new_adt_id
                    and     cat_id = lt_old_data(i).new_cat_id
                    and     rownum = 1;
                exception
                    when no_data_found then
                        ln_existing_ars_id := null;
                end;
            end if;
            
            -- Result aanmaken of hergebruiken
            if ln_existing_ars_id is not null then
                ln_ars_id := ln_existing_ars_id;
                ln_reused_results := ln_reused_results + 1;
                
                -- Update counter_errors voor bestaande records
                update icca_adt_results
                set counter_errors = ln_counter_errors
                where id = ln_ars_id;
            else
                insert into icca_adt_results(   adt_id                      
                                            ,   cat_id              
                                            ,   counter_elements    
                                            ,   approve_limit       
                                            ,   counter_errors
                                            ,   score               
                                            ,   is_sufficient
                                            ,   migrated_data               
                                        ) values (
                                                lt_old_data(i).new_adt_id
                                            ,   lt_old_data(i).new_cat_id
                                            ,   lt_old_data(i).counter_elements
                                            ,   lt_old_data(i).approve_limit
                                            ,   ln_counter_errors
                                            ,   lt_old_data(i).score
                                            ,   lt_old_data(i).is_sufficient
                                            ,   'Y'
                                            )
                            returning id into ln_ars_id;
                
                ln_new_results := ln_new_results + 1;
            end if;
            
            -- Update oude ResultAuditCategory tabel (idempotent)
            update  ResultAuditCategory2
            set     ars_id = ln_ars_id
            where   idaudit = lt_old_data(i).old_adt_id
            and     idcategory = lt_old_data(i).old_cat_id;
            
            ln_total_results := ln_total_results + 1;
            
            -- Batch commit
            if mod(ln_total_results, ln_commit_batch) = 0 then
                commit;
            end if;
            
            -- Progress indicator
            if mod(ln_total_results, ln_progress_batch) = 0 then
                dbms_output.put_line('Progress: ' || ln_total_results || ' / ' || lt_old_data.count || 
                                   ' (' || round((ln_total_results / lt_old_data.count) * 100, 1) || '%)');
            end if;
            
        exception
            when others then
                ln_failed_results := ln_failed_results + 1;
                ln_total_results := ln_total_results + 1;
                
                if ln_failed_results <= 10 then
                    dbms_output.put_line('✗ Error #' || ln_failed_results || 
                                       ' - adt_id: ' || lt_old_data(i).new_adt_id || 
                                       ', cat_id: ' || lt_old_data(i).new_cat_id || 
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
        dbms_output.put_line('AUDIT RESULTS MIGRATION SUMMARY');
        dbms_output.put_line('========================================');
        dbms_output.put_line('Total results processed:        ' || ln_total_results);
        dbms_output.put_line('  ✓ New results created:        ' || ln_new_results);
        dbms_output.put_line('  ✓ Existing results reused:    ' || ln_reused_results);
        dbms_output.put_line('  ✗ Failed results:             ' || ln_failed_results);
        dbms_output.put_line('');
        dbms_output.put_line('Error counts calculated:');
        dbms_output.put_line('  - Results with errors:        ' || ln_with_errors);
        dbms_output.put_line('  - Results without errors:     ' || (ln_total_results - ln_with_errors - ln_failed_results));
        dbms_output.put_line('');
        dbms_output.put_line('Duration:                       ' || round(ln_seconds, 2) || ' seconds');
        if ln_seconds > 0 then
            dbms_output.put_line('Average speed:                  ' || round(ln_total_results / ln_seconds, 0) || ' records/second');
        end if;
        dbms_output.put_line('========================================');
        
        -- Check for records NOT migrated
        select count(*) into ln_not_migrated 
        from ResultAuditCategory2 
        where ars_id is null;
        
        if ln_not_migrated > 0 then
            dbms_output.put_line('');
            dbms_output.put_line('⚠ Records NOT migrated: ' || ln_not_migrated);
        else
            dbms_output.put_line('');
            dbms_output.put_line('✓ All records migrated successfully!');
        end if;
    end;
end;
/