set serveroutput on;
declare
    cursor c_get_old_data
    is
        select  fom.id                                                  as old_fom_id
        ,       adt.id                                                  as old_adt_id
        ,       pfr.id                                                  as old_pfr_id
        ,       adt.auditcode                                           as audit_code
        ,       adt.adt_id                                              as new_adt_id
        ,       pfr1.id                                                 as new_pfr_id
        ,       flr.flr_id                                              as new_flr_id
        ,       cat.cat_id                                              as new_cat_id
        ,       ara.ara_id                                              as new_ara_id
        ,       substr(fom.areacode,instr(fom.areacode, '.') + 1)       as area_number
        ,       fom.counterelement                                      as element_count        
        ,       fom.faults                                              as error_count
        ,       fom.comments                                            as remark        
        ,       nvl(fom.date_, sysdate)                                 as form_date
        ,       fom.areacode                                            as migrated_area_code
        ,       substr(fom.areacode, 1, instr(fom.areacode, '-') - 1)   as verdieping 
        ,       substr(fom.areacode,instr(fom.areacode, '-') + 1,instr(fom.areacode, '.') - instr(fom.areacode, '-') - 1) as area
        from    forms             fom
        join    audits            adt on fom.auditid = adt.id
        join    floors            flr on fom.floorid = flr.id
        join    categories        cat on fom.categoryid = cat.id
        -- join    AreaDescriptions ara 
        --     on ara.ModuleId = 4 
        --     and upper(trim(ara.abbreviation)) = upper(trim(
        --             substr(fom.areacode, 
        --                 instr(fom.areacode, '-', 1, 2) + 1,  -- Start NA de 2e '-'
        --                 instr(fom.areacode, '.') - instr(fom.areacode, '-', 1, 2) - 1  -- Tot de '.'
        --             )
        --         ))
        left join (
            select  fom.id as form_id
            ,       ara.id as ara_id
            ,       row_number() over (
                        partition by fom.id 
                        order by 
                            case 
                                -- Prioriteit: exacte match op 3-letter code
                                when length(trim(ara.abbreviation)) = 3 
                                    and upper(trim(ara.abbreviation)) = upper(trim(REGEXP_SUBSTR(fom.areacode, '[A-Za-z]{3}'))) 
                                then 1
                                -- Anders: match op eerste letters
                                when upper(trim(ara.abbreviation)) LIKE upper(substr(REGEXP_SUBSTR(fom.areacode, '[A-Za-z]+'), 1, 3)) || '%' 
                                then 2
                                else 3
                            end
                    ) as rn
            from    forms fom
            cross join AreaDescriptions ara
            where   ara.ModuleId = 4
        ) ara_match 
            on ara_match.form_id = fom.id 
            and ara_match.rn = 1
        join AreaDescriptions ara on ara.id = ara_match.ara_id        
        join    users_auditor    pfr on fom.auditby_id = pfr.id
        join    icca_performers  pfr1 on pfr1.usr_id = pfr.usr_id
        where   substr(fom.areacode,instr(fom.areacode, '-') + 1,instr(fom.areacode, '.') - instr(fom.areacode, '-') - 1) is not null
        and     adt.adt_id is not null
        and     pfr.usr_id is not null
        and     flr.flr_id is not null
        and     cat.cat_id is not null
        and     ara.ara_id is not null
        and     fom.fom_id is null
        and     fom.date_ > to_date('01-JAN-2018', 'DD-MM-YYYY')
        ;
    
    type t_old_data is table of c_get_old_data%rowtype;
    lt_old_data t_old_data;
    ln_fom_id number;
    ln_existing_fom_id number;
    
    ln_total_forms number := 0;
    ln_new_forms number := 0;
    ln_reused_forms number := 0;
    ln_failed_forms number := 0;
    
    ln_commit_batch constant number := 1000;  -- Commit elke 1000 records
    ln_progress_batch constant number := 5000; -- Progress elke 5000 records
    ln_start_time timestamp := systimestamp;
begin
    dbms_output.put_line('========================================');
    dbms_output.put_line('Starting migration...');
    dbms_output.put_line('========================================');
    
    open    c_get_old_data;
    fetch   c_get_old_data bulk collect into lt_old_data;
    close   c_get_old_data;
    
    dbms_output.put_line('Total records to process: ' || lt_old_data.count);
    dbms_output.put_line('');
    
    for i in 1 .. lt_old_data.count 
    loop
        begin
            ln_fom_id := null;
            ln_existing_fom_id := null;
            
            -- ============================================
            -- AUDIT FORM MIGRATIE (met duplicate check)
            -- ============================================
            
            -- Check of form al gemigreerd is via oude tabel
            begin
                select fom_id 
                into ln_existing_fom_id
                from forms
                where id = lt_old_data(i).old_fom_id
                and fom_id is not null;
            exception
                when no_data_found then
                    ln_existing_fom_id := null;
            end;
            
            -- Als nog niet gemigreerd, check op unieke combinatie
            if ln_existing_fom_id is null then
                begin
                    select  id 
                    into    ln_existing_fom_id
                    from    icca_adt_forms
                    where   adt_id = lt_old_data(i).new_adt_id
                    and     migrated_area_code = lt_old_data(i).migrated_area_code
                    and     rownum = 1;
                exception
                    when no_data_found then
                        ln_existing_fom_id := null;
                end;
            end if;
            
            -- Form aanmaken of hergebruiken
            if ln_existing_fom_id is not null then
                ln_fom_id := ln_existing_fom_id;
                ln_reused_forms := ln_reused_forms + 1;
            else
                insert into icca_adt_forms(     adt_id          
                                            ,   pfr_id          
                                            ,   flr_id          
                                            ,   cat_id          
                                            ,   ara_id          
                                            ,   area_number     
                                            ,   element_count   
                                            ,   remark          
                                            ,   form_date       
                                            ,   error_count
                                            ,   migrated_area_code
                                            ,   migrated_data   
                                        ) values (
                                                lt_old_data(i).new_adt_id
                                            ,   lt_old_data(i).new_pfr_id
                                            ,   lt_old_data(i).new_flr_id
                                            ,   lt_old_data(i).new_cat_id
                                            ,   lt_old_data(i).new_ara_id
                                            ,   lt_old_data(i).area_number
                                            ,   lt_old_data(i).element_count
                                            ,   lt_old_data(i).remark
                                            ,   lt_old_data(i).form_date
                                            ,   lt_old_data(i).error_count
                                            ,   lt_old_data(i).migrated_area_code
                                            ,   'Y'
                                            )
                            returning id into ln_fom_id;
                
                ln_new_forms := ln_new_forms + 1;
            end if;
            
            -- Update oude forms tabel (idempotent)
            update  forms
            set     fom_id = ln_fom_id
            where   id = lt_old_data(i).old_fom_id;
            
            ln_total_forms := ln_total_forms + 1;
            
            -- Batch commit voor betere performance
            if mod(ln_total_forms, ln_commit_batch) = 0 then
                commit;
            end if;
            
            -- Progress indicator
            if mod(ln_total_forms, ln_progress_batch) = 0 then
                dbms_output.put_line('Progress: ' || ln_total_forms || ' / ' || lt_old_data.count || 
                                   ' (' || round((ln_total_forms / lt_old_data.count) * 100, 1) || '%)');
            end if;
            
        exception
            when others then
                ln_failed_forms := ln_failed_forms + 1;
                ln_total_forms := ln_total_forms + 1;
                
                -- Log alleen eerste 10 errors (om output beheersbaar te houden)
                if ln_failed_forms <= 10 then
                    dbms_output.put_line('✗ Error #' || ln_failed_forms || 
                                       ' - old_fom_id: ' || lt_old_data(i).old_fom_id || 
                                       ' - ' || substr(sqlerrm, 1, 200));
                end if;
                
                continue;
        end;
    end loop;
    
    -- Final commit
    commit;
    
    -- Calculate duration
    declare
        ln_duration interval day to second;
        ln_seconds number;
    begin
        ln_duration := systimestamp - ln_start_time;
        ln_seconds := extract(day from ln_duration) * 86400 + 
                     extract(hour from ln_duration) * 3600 + 
                     extract(minute from ln_duration) * 60 + 
                     extract(second from ln_duration);
        
        -- Summary rapport
        dbms_output.put_line('');
        dbms_output.put_line('========================================');
        dbms_output.put_line('AUDIT FORM MIGRATION SUMMARY');
        dbms_output.put_line('========================================');
        dbms_output.put_line('Total forms processed:          ' || ln_total_forms);
        dbms_output.put_line('  ✓ New forms created:          ' || ln_new_forms);
        dbms_output.put_line('  ✓ Existing forms reused:      ' || ln_reused_forms);
        dbms_output.put_line('  ✗ Failed forms (errors):      ' || ln_failed_forms);
        dbms_output.put_line('');
        dbms_output.put_line('Duration:                       ' || round(ln_seconds, 2) || ' seconds');
        dbms_output.put_line('Average speed:                  ' || round(ln_total_forms / ln_seconds, 0) || ' records/second');
        dbms_output.put_line('========================================');
        
        -- Validation check
        if (ln_new_forms + ln_reused_forms + ln_failed_forms) != ln_total_forms then
            dbms_output.put_line('⚠ WARNING: Counter mismatch detected!');
            dbms_output.put_line('   Expected: ' || ln_total_forms);
            dbms_output.put_line('   Actual:   ' || (ln_new_forms + ln_reused_forms + ln_failed_forms));
        end if;
    end;
end;
/



select  fom.areacode
,       ara.*
from    forms             fom 
join    audits            adt on fom.auditid = adt.id -- 7868  Rows
join    floors            flr on fom.floorid = flr.id -- 7868  Rows
join    categories        cat on fom.categoryid = cat.id -- 7868  Rows
join    AreaDescriptions ara 
    on ara.ModuleId = 4 
    and upper(trim(ara.abbreviation)) = upper(trim(
            substr(fom.areacode, 
                   instr(fom.areacode, '-', 1, 2) + 1,  -- Start NA de 2e '-'
                   instr(fom.areacode, '.') - instr(fom.areacode, '-', 1, 2) - 1  -- Tot de '.'
            )
        )) -- 3762  Rows
--join AreaDescriptions ara 
--    on ara.ModuleId = 4 
--    and (
--        -- Exacte matches
--        upper(trim(ara.abbreviation)) = upper(trim(REGEXP_SUBSTR(fom.areacode, '[^-.]+', 1, 2)))
--        OR
--        upper(trim(ara.abbreviation)) = upper(trim(REGEXP_SUBSTR(fom.areacode, '[^-.]+', 1, 3)))
--        OR
--        -- Fuzzy match (eerste 2-3 karakters)
--        upper(trim(ara.abbreviation)) LIKE upper(substr(REGEXP_SUBSTR(fom.areacode, '[A-Za-z]+'), 1, 3)) || '%'
--    )
where   fom_id is null -- 7868  Rows
--and ara.id is null -- 4106  Rows