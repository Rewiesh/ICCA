declare
    cursor c_get_old_data
    is
        select  ket.id                                                  as old_ket_id
        ,       ket.ElementLabel                                        as name
        ,       case when ket.ElementStatus = 1 then 'Y' else 'N' end   as active
        from    Element ket
        -- where ket.ket_id is null
        ;
    
    type t_old_data is table of c_get_old_data%rowtype;
    lt_old_data t_old_data;
    ln_ket_id number;
    ln_kcn_id number;
    ln_existing_ket_id number;
    ln_existing_kcn_id number;
    
    ln_total_elements number := 0;
    ln_new_elements number := 0;
    ln_reused_elements number := 0;
    ln_new_ket_clients number := 0;
    ln_reused_ket_clients number := 0;
begin
    open    c_get_old_data;
    fetch   c_get_old_data bulk collect into lt_old_data;
    close   c_get_old_data;
    
    for i in 1 .. lt_old_data.count 
    loop
        begin
            ln_ket_id := null;
            ln_existing_ket_id := null;
            
            -- ============================================
            -- STAP 1: KPI ELEMENT MIGRATIE (met duplicate check)
            -- ============================================
            
            -- Check of element al gemigreerd is via oude tabel
            begin
                select ket_id 
                into ln_existing_ket_id
                from Element
                where id = lt_old_data(i).old_ket_id
                and ket_id is not null;
            exception
                when no_data_found then
                    ln_existing_ket_id := null;
            end;
            
            -- Als nog niet gemigreerd, check op naam
            if ln_existing_ket_id is null then
                begin
                    select  id 
                    into    ln_existing_ket_id
                    from    icca_kpi_elementen
                    where   upper(name) = upper(lt_old_data(i).name)
                    and     rownum = 1;
                exception
                    when no_data_found then
                        ln_existing_ket_id := null;
                end;
            end if;
            
            -- KPI Element aanmaken of hergebruiken
            if ln_existing_ket_id is not null then
                ln_ket_id := ln_existing_ket_id;
                ln_reused_elements := ln_reused_elements + 1;
                dbms_output.put_line('✓ Reusing KPI element - ket_id: ' || ln_ket_id || ' for: ' || lt_old_data(i).name);
            else
                insert into icca_kpi_elementen(     name      
                                                ,   active     
                                                ,   migrated_data          
                                            ) values (
                                                    lt_old_data(i).name
                                                ,   lt_old_data(i).active
                                                ,   'Y'
                                            )
                                        returning id into ln_ket_id;
                
                ln_new_elements := ln_new_elements + 1;
                dbms_output.put_line('✓ New KPI element created - ket_id: ' || ln_ket_id || ' for: ' || lt_old_data(i).name);
            end if;
            
            -- Update oude Element tabel (idempotent)
            update  Element
            set     ket_id = ln_ket_id
            where   id = lt_old_data(i).old_ket_id;
            
            -- ============================================
            -- STAP 2: ELEMENT-CLIENT MAPPING (met duplicate check)
            -- ============================================
            
            for element in (
                select  ln_ket_id       as new_ket_id
                ,       cnt.cnt_id      as new_cnt_id
                ,       cnt.id          as old_cnt_id
                ,       kcn.idelement   as old_ket_id
                ,       kcn.idclient    as old_client_id
                from    ElementClient kcn  
                join    users_client cnt on cnt.id = kcn.idclient
                where   kcn.idelement = lt_old_data(i).old_ket_id
                and     cnt.cnt_id is not null
            ) loop
                begin
                    ln_kcn_id := null;
                    ln_existing_kcn_id := null;
                    
                    -- Check of mapping al gemigreerd is via oude tabel
                    begin
                        select kcn_id 
                        into ln_existing_kcn_id
                        from ElementClient
                        where idelement = element.old_ket_id
                        and idclient = element.old_client_id
                        and kcn_id is not null;
                    exception
                        when no_data_found then
                            ln_existing_kcn_id := null;
                    end;
                    
                    -- Als nog niet gemigreerd, check in icca_ket_clients
                    if ln_existing_kcn_id is null then
                        begin
                            select id
                            into ln_existing_kcn_id
                            from icca_ket_clients
                            where ket_id = element.new_ket_id
                            and cnt_id = element.new_cnt_id
                            and rownum = 1;
                        exception
                            when no_data_found then
                                ln_existing_kcn_id := null;
                        end;
                    end if;
                    
                    -- Mapping aanmaken of hergebruiken
                    if ln_existing_kcn_id is not null then
                        ln_kcn_id := ln_existing_kcn_id;
                        ln_reused_ket_clients := ln_reused_ket_clients + 1;
                    else
                        insert into icca_ket_clients(   ket_id
                                                    ,   cnt_id
                                                    ,   migrated_data
                                                ) values (
                                                        element.new_ket_id
                                                    ,   element.new_cnt_id
                                                    ,   'Y'
                                                )
                                            returning id into ln_kcn_id;
                        
                        ln_new_ket_clients := ln_new_ket_clients + 1;
                    end if;
                    
                    -- Update ElementClient tabel met kcn_id (idempotent)
                    update  ElementClient
                    set     kcn_id = ln_kcn_id
                    where   idelement = element.old_ket_id
                    and     idclient = element.old_client_id;
                    
                exception
                    when others then
                        dbms_output.put_line('  ⚠ Error migrating element-client mapping: ' || sqlerrm);
                end;
            end loop;
            
            ln_total_elements := ln_total_elements + 1;
            
        exception
            when others then
                dbms_output.put_line('✗ Error processing KPI element: ' || lt_old_data(i).name || ' - ' || sqlerrm);
                dbms_output.put_line('  old_ket_id: ' || lt_old_data(i).old_ket_id);
                continue;
        end;
    end loop;
    
    commit;
    
    -- Summary rapport
    dbms_output.put_line('');
    dbms_output.put_line('========================================');
    dbms_output.put_line('KPI ELEMENT MIGRATION SUMMARY');
    dbms_output.put_line('========================================');
    dbms_output.put_line('Total KPI elements processed:   ' || ln_total_elements);
    dbms_output.put_line('  - New elements created:       ' || ln_new_elements);
    dbms_output.put_line('  - Existing elements reused:   ' || ln_reused_elements);
    dbms_output.put_line('');
    dbms_output.put_line('Element-Client mappings:');
    dbms_output.put_line('  - New mappings created:       ' || ln_new_ket_clients);
    dbms_output.put_line('  - Existing mappings reused:   ' || ln_reused_ket_clients);
    dbms_output.put_line('========================================');
end;
/