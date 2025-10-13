set serveroutput on;
declare
    -- Default IDs ophalen (run ONCE at start)
    ln_default_ete_id number;
    ln_default_epe_id number;
    
    cursor c_get_old_data
    is
        with w_errortype
        as  (   select  errortypeid
                ,       ete_id
                from    ErrorType
                where   ete_id is not null
                group by errortypeid, ete_id
        )
        select  frr.errorelementid          as frr_pk_id
        ,       frr.errortypeid             as old_ete_id
        ,       frr.elementid               as old_epe_id
        ,       fom.fom_id                  as new_fom_id
        ,       ete.ete_id                  as new_ete_id
        ,       epe.epe_id                  as new_epe_id
        ,       frr.count                   as error_count
        ,       frr.logbook                 as log_book_remark
        ,       frr.technicalaspects        as technical_aspects_remark
        ,       img1.doc_id                 as log_book_image_id
        ,       img2.doc_id                 as technical_aspects_image_id
        from    formerrorelement  frr
        join    forms             fom on fom.id = frr.formid
        left join w_errortype     ete on ete.errortypeid = frr.errortypeid
        left join ElementType     epe on epe.elementtypeid = frr.elementid and epe.epe_id is not null
        left join images          img1 on img1.imageid = frr.logbookimage
        left join images          img2 on img2.imageid = frr.technicalaspectsimage
        where   fom.fom_id is not null
        -- and frr.for_id is null
        ;
    
    type t_old_data is table of c_get_old_data%rowtype;
    lt_old_data t_old_data;
    ln_for_id number;
    ln_existing_for_id number;
    ln_use_ete_id number;
    ln_use_epe_id number;
    lv_added_default_ete varchar2(1);
    lv_added_default_epe varchar2(1);
    lv_remark varchar2(4000);
    
    ln_total_errors number := 0;
    ln_new_errors number := 0;
    ln_reused_errors number := 0;
    ln_failed_errors number := 0;
    ln_with_default_ete number := 0;
    ln_with_default_epe number := 0;
    ln_with_logbook_image number := 0;
    ln_with_technical_image number := 0;
    
    ln_commit_batch constant number := 1000;
    ln_progress_batch constant number := 5000;
    ln_start_time timestamp := systimestamp;
begin
    dbms_output.put_line('========================================');
    dbms_output.put_line('Starting form errors migration...');
    dbms_output.put_line('========================================');
    
    -- Haal default IDs op (eerste record uit elke tabel)
    select id into ln_default_ete_id 
    from icca_error_types 
    where rownum = 1 
    order by id;
    
    select id into ln_default_epe_id 
    from icca_elementtypes 
    where rownum = 1 
    order by id;
    
    dbms_output.put_line('Default error type ID: ' || ln_default_ete_id);
    dbms_output.put_line('Default element type ID: ' || ln_default_epe_id);
    dbms_output.put_line('');
    
    open    c_get_old_data;
    fetch   c_get_old_data bulk collect into lt_old_data;
    close   c_get_old_data;
    
    dbms_output.put_line('Total records to process: ' || lt_old_data.count);
    dbms_output.put_line('');
    
    for i in 1 .. lt_old_data.count 
    loop
        begin
            ln_for_id := null;
            ln_existing_for_id := null;
            ln_use_ete_id := null;
            ln_use_epe_id := null;
            lv_added_default_ete := 'N';
            lv_added_default_epe := 'N';
            lv_remark := null;
            
            -- ============================================
            -- Determine welke IDs te gebruiken
            -- ============================================
            
            -- Error Type ID
            if lt_old_data(i).new_ete_id is not null then
                ln_use_ete_id := lt_old_data(i).new_ete_id;
            else
                ln_use_ete_id := ln_default_ete_id;
                lv_added_default_ete := 'Y';
                ln_with_default_ete := ln_with_default_ete + 1;
                lv_remark := lv_remark || 'Missing errortypeid (was: ' || 
                             nvl(to_char(lt_old_data(i).old_ete_id), 'NULL') || '). ';
            end if;
            
            -- Element Type ID
            if lt_old_data(i).new_epe_id is not null then
                ln_use_epe_id := lt_old_data(i).new_epe_id;
            else
                ln_use_epe_id := ln_default_epe_id;
                lv_added_default_epe := 'Y';
                ln_with_default_epe := ln_with_default_epe + 1;
                lv_remark := lv_remark || 'Missing elementid (was: ' || 
                             nvl(to_char(lt_old_data(i).old_epe_id), 'NULL') || '). ';
            end if;
            
            -- ============================================
            -- FORM ERROR MIGRATIE (met duplicate check)
            -- ============================================
            
            -- Check of error al gemigreerd is via oude tabel
            begin
                select for_id 
                into ln_existing_for_id
                from formerrorelement
                where errorelementid = lt_old_data(i).frr_pk_id
                and for_id is not null;
            exception
                when no_data_found then
                    ln_existing_for_id := null;
            end;
            
            -- Als nog niet gemigreerd, check op unieke combinatie
            if ln_existing_for_id is null then
                begin
                    select  id 
                    into    ln_existing_for_id
                    from    icca_fom_errors
                    where   fom_id = lt_old_data(i).new_fom_id
                    and     ete_id = ln_use_ete_id
                    and     epe_id = ln_use_epe_id
                    and     rownum = 1;
                exception
                    when no_data_found then
                        ln_existing_for_id := null;
                end;
            end if;
            
            -- Form Error aanmaken of hergebruiken
            if ln_existing_for_id is not null then
                ln_for_id := ln_existing_for_id;
                ln_reused_errors := ln_reused_errors + 1;
            else
                insert into icca_fom_errors(    fom_id                      
                                            ,   ete_id                      
                                            ,   epe_id                      
                                            ,   error_count                 
                                            ,   log_book_remark             
                                            ,   technical_aspects_remark    
                                            ,   log_book_image_id           
                                            ,   technical_aspects_image_id
                                            ,   remark
                                            ,   added_default_ete_id
                                            ,   added_default_epe_id
                                            ,   migrated_data               
                                        ) values (
                                                lt_old_data(i).new_fom_id
                                            ,   ln_use_ete_id
                                            ,   ln_use_epe_id
                                            ,   lt_old_data(i).error_count
                                            ,   lt_old_data(i).log_book_remark
                                            ,   lt_old_data(i).technical_aspects_remark
                                            ,   lt_old_data(i).log_book_image_id
                                            ,   lt_old_data(i).technical_aspects_image_id
                                            ,   lv_remark
                                            ,   lv_added_default_ete
                                            ,   lv_added_default_epe
                                            ,   'Y'
                                            )
                            returning id into ln_for_id;
                
                ln_new_errors := ln_new_errors + 1;
                
                -- Count images
                if lt_old_data(i).log_book_image_id is not null then
                    ln_with_logbook_image := ln_with_logbook_image + 1;
                end if;
                if lt_old_data(i).technical_aspects_image_id is not null then
                    ln_with_technical_image := ln_with_technical_image + 1;
                end if;
            end if;
            
            -- Update oude formerrorelement tabel (idempotent)
            update  formerrorelement
            set     for_id = ln_for_id
            where   errorelementid = lt_old_data(i).frr_pk_id;
            
            ln_total_errors := ln_total_errors + 1;
            
            -- Batch commit
            if mod(ln_total_errors, ln_commit_batch) = 0 then
                commit;
            end if;
            
            -- Progress indicator
            if mod(ln_total_errors, ln_progress_batch) = 0 then
                dbms_output.put_line('Progress: ' || ln_total_errors || ' / ' || lt_old_data.count || 
                                   ' (' || round((ln_total_errors / lt_old_data.count) * 100, 1) || '%)');
            end if;
            
        exception
            when others then
                ln_failed_errors := ln_failed_errors + 1;
                ln_total_errors := ln_total_errors + 1;
                
                if ln_failed_errors <= 10 then
                    dbms_output.put_line('✗ Error #' || ln_failed_errors || 
                                       ' - frr_pk_id: ' || lt_old_data(i).frr_pk_id || 
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
        dbms_output.put_line('FORM ERROR MIGRATION SUMMARY');
        dbms_output.put_line('========================================');
        dbms_output.put_line('Total form errors processed:    ' || ln_total_errors);
        dbms_output.put_line('  ✓ New errors created:         ' || ln_new_errors);
        dbms_output.put_line('  ✓ Existing errors reused:     ' || ln_reused_errors);
        dbms_output.put_line('  ✗ Failed errors:              ' || ln_failed_errors);
        dbms_output.put_line('');
        dbms_output.put_line('Default values used:');
        dbms_output.put_line('  ⚠ Default error type ID:      ' || ln_with_default_ete);
        dbms_output.put_line('  ⚠ Default element type ID:    ' || ln_with_default_epe);
        dbms_output.put_line('');
        dbms_output.put_line('Images migrated:');
        dbms_output.put_line('  - Logbook images:             ' || ln_with_logbook_image);
        dbms_output.put_line('  - Technical aspect images:    ' || ln_with_technical_image);
        dbms_output.put_line('');
        dbms_output.put_line('Duration:                       ' || round(ln_seconds, 2) || ' seconds');
        dbms_output.put_line('Average speed:                  ' || round(ln_total_errors / ln_seconds, 0) || ' records/second');
        dbms_output.put_line('========================================');
        
        -- Check for records NOT migrated
        select count(*) into ln_not_migrated from formerrorelement where for_id is null;
        
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