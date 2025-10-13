set serveroutput on;
declare
    cursor c_get_old_data
    is
        select  id              as old_sce_id
        ,       ratingvalue     as score
        from    ratingvalue
        -- where sce_id is null
        ;
    
    type t_old_data is table of c_get_old_data%rowtype;
    lt_old_data t_old_data;
    ln_sce_id number;
    ln_existing_sce_id number;
    
    ln_total_scores number := 0;
    ln_new_scores number := 0;
    ln_reused_scores number := 0;
begin
    open    c_get_old_data;
    fetch   c_get_old_data bulk collect into lt_old_data;
    close   c_get_old_data;
    
    for i in 1 .. lt_old_data.count 
    loop
        begin
            ln_sce_id := null;
            ln_existing_sce_id := null;
            
            -- ============================================
            -- SCORE MIGRATIE (met duplicate check)
            -- ============================================
            
            -- Check of score al gemigreerd is via oude tabel
            begin
                select sce_id 
                into ln_existing_sce_id
                from ratingvalue
                where id = lt_old_data(i).old_sce_id
                and sce_id is not null;
            exception
                when no_data_found then
                    ln_existing_sce_id := null;
            end;
            
            -- Als nog niet gemigreerd, check op score waarde
            if ln_existing_sce_id is null then
                begin
                    select  id 
                    into    ln_existing_sce_id
                    from    icca_scores
                    where   score = lt_old_data(i).score
                    and     rownum = 1;
                exception
                    when no_data_found then
                        ln_existing_sce_id := null;
                end;
            end if;
            
            -- Score aanmaken of hergebruiken
            if ln_existing_sce_id is not null then
                ln_sce_id := ln_existing_sce_id;
                ln_reused_scores := ln_reused_scores + 1;
                dbms_output.put_line('✓ Reusing score - sce_id: ' || ln_sce_id || ' for score: ' || lt_old_data(i).score);
            else
                insert into icca_scores(    score         
                                        ,   migrated_data     
                                    ) values (
                                        lt_old_data(i).score
                                    ,   'Y'
                                    )
                            returning id into ln_sce_id;
                
                ln_new_scores := ln_new_scores + 1;
                dbms_output.put_line('✓ New score created - sce_id: ' || ln_sce_id || ' for score: ' || lt_old_data(i).score);
            end if;
            
            -- Update oude ratingvalue tabel (idempotent)
            update  ratingvalue
            set     sce_id = ln_sce_id
            where   id = lt_old_data(i).old_sce_id;
            
            ln_total_scores := ln_total_scores + 1;
            
        exception
            when others then
                dbms_output.put_line('✗ Error processing score: ' || lt_old_data(i).score || ' - ' || sqlerrm);
                dbms_output.put_line('  old_sce_id: ' || lt_old_data(i).old_sce_id);
                continue;
        end;
    end loop;
    
    commit;
    
    -- Summary rapport
    dbms_output.put_line('');
    dbms_output.put_line('========================================');
    dbms_output.put_line('SCORE MIGRATION SUMMARY');
    dbms_output.put_line('========================================');
    dbms_output.put_line('Total scores processed:         ' || ln_total_scores);
    dbms_output.put_line('  - New scores created:         ' || ln_new_scores);
    dbms_output.put_line('  - Existing scores reused:     ' || ln_reused_scores);
    dbms_output.put_line('========================================');
end;
/