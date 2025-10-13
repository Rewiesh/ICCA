declare
    cursor c_get_old_data
    is
        select  epe.elementtypeid       as old_epe_id
        ,       epe.elementtypevalue    as name
        from    ElementType epe
        -- where epe.epe_id is null
        ;
    
    type t_old_data is table of c_get_old_data%rowtype;
    lt_old_data t_old_data;
    ln_epe_id number;
    ln_era_id number;
    ln_existing_epe_id number;
    ln_existing_era_id number;
    
    ln_total_elementtypes number := 0;
    ln_new_elementtypes number := 0;
    ln_reused_elementtypes number := 0;
    ln_new_epe_areas number := 0;
    ln_reused_epe_areas number := 0;
begin
    open    c_get_old_data;
    fetch   c_get_old_data bulk collect into lt_old_data;
    close   c_get_old_data;
    
    for i in 1 .. lt_old_data.count 
    loop
        begin
            ln_epe_id := null;
            ln_existing_epe_id := null;
            
            -- ============================================
            -- STAP 1: ELEMENTTYPE MIGRATIE (met duplicate check)
            -- ============================================
            
            -- Check of elementtype al gemigreerd is via oude tabel
            begin
                select epe_id 
                into ln_existing_epe_id
                from ElementType
                where ElementTypeId = lt_old_data(i).old_epe_id
                and epe_id is not null;
            exception
                when no_data_found then
                    ln_existing_epe_id := null;
            end;
            
            -- Als nog niet gemigreerd, check op naam
            if ln_existing_epe_id is null then
                begin
                    select  id 
                    into    ln_existing_epe_id
                    from    icca_elementtypes
                    where   upper(name) = upper(lt_old_data(i).name)
                    and     rownum = 1;
                exception
                    when no_data_found then
                        ln_existing_epe_id := null;
                end;
            end if;
            
            -- ElementType aanmaken of hergebruiken
            if ln_existing_epe_id is not null then
                ln_epe_id := ln_existing_epe_id;
                ln_reused_elementtypes := ln_reused_elementtypes + 1;
                dbms_output.put_line('✓ Reusing elementtype - epe_id: ' || ln_epe_id || ' for: ' || lt_old_data(i).name);
            else
                insert into icca_elementtypes(  name      
                                            ,   migrated_data          
                                        ) values (
                                                lt_old_data(i).name
                                            ,   'Y'
                                        )
                                    returning id into ln_epe_id;
                
                ln_new_elementtypes := ln_new_elementtypes + 1;
                dbms_output.put_line('✓ New elementtype created - epe_id: ' || ln_epe_id || ' for: ' || lt_old_data(i).name);
            end if;
            
            -- Update oude ElementType tabel (idempotent)
            update  ElementType
            set     epe_id = ln_epe_id
            where   ElementTypeId = lt_old_data(i).old_epe_id;
            
            -- ============================================
            -- STAP 2: ELEMENTTYPE-AREA MAPPING (met duplicate check)
            -- ============================================
            
            for element in (
                select  ln_epe_id       as new_epe_id
                ,       ara.id          as old_ara_id
                ,       ara.ara_id      as new_ara_id
                ,       era.elementtypeid as old_epe_id
                from    AreaDescription_ElementType era
                join    AreaDescriptions ara on ara.id = era.AreaDescId
                where   era.elementtypeid = lt_old_data(i).old_epe_id
                and     ara.ara_id is not null
                and     era.AreaDescModuleId = 4
            ) loop
                begin
                    ln_era_id := null;
                    ln_existing_era_id := null;
                    
                    -- Check of mapping al gemigreerd is via oude tabel
                    begin
                        select era_id 
                        into ln_existing_era_id
                        from AreaDescription_ElementType
                        where elementtypeid = element.old_epe_id
                        and AreaDescId = element.old_ara_id
                        and era_id is not null;
                    exception
                        when no_data_found then
                            ln_existing_era_id := null;
                    end;
                    
                    -- Als nog niet gemigreerd, check in icca_epe_areas
                    if ln_existing_era_id is null then
                        begin
                            select id
                            into ln_existing_era_id
                            from icca_epe_areas
                            where epe_id = element.new_epe_id
                            and ara_id = element.new_ara_id
                            and rownum = 1;
                        exception
                            when no_data_found then
                                ln_existing_era_id := null;
                        end;
                    end if;
                    
                    -- Mapping aanmaken of hergebruiken
                    if ln_existing_era_id is not null then
                        ln_era_id := ln_existing_era_id;
                        ln_reused_epe_areas := ln_reused_epe_areas + 1;
                    else
                        insert into icca_epe_areas( epe_id
                                                ,   ara_id
                                                ,   migrated_data
                                            ) values (
                                                    element.new_epe_id
                                                ,   element.new_ara_id
                                                ,   'Y'
                                            )
                                        returning id into ln_era_id;
                        
                        ln_new_epe_areas := ln_new_epe_areas + 1;
                    end if;
                    
                    -- Update AreaDescription_ElementType tabel met era_id (idempotent)
                    update  AreaDescription_ElementType
                    set     era_id = ln_era_id
                    where   elementtypeid = element.old_epe_id
                    and     AreaDescId = element.old_ara_id;
                    
                exception
                    when others then
                        dbms_output.put_line('  ⚠ Error migrating elementtype-area mapping: ' || sqlerrm);
                end;
            end loop;
            
            ln_total_elementtypes := ln_total_elementtypes + 1;
            
        exception
            when others then
                dbms_output.put_line('✗ Error processing elementtype: ' || lt_old_data(i).name || ' - ' || sqlerrm);
                dbms_output.put_line('  old_epe_id: ' || lt_old_data(i).old_epe_id);
                continue;
        end;
    end loop;
    
    commit;
    
    -- Summary rapport
    dbms_output.put_line('');
    dbms_output.put_line('========================================');
    dbms_output.put_line('ELEMENTTYPE MIGRATION SUMMARY');
    dbms_output.put_line('========================================');
    dbms_output.put_line('Total elementtypes processed:   ' || ln_total_elementtypes);
    dbms_output.put_line('  - New elementtypes created:   ' || ln_new_elementtypes);
    dbms_output.put_line('  - Existing elementtypes reused: ' || ln_reused_elementtypes);
    dbms_output.put_line('');
    dbms_output.put_line('ElementType-Area mappings:');
    dbms_output.put_line('  - New mappings created:       ' || ln_new_epe_areas);
    dbms_output.put_line('  - Existing mappings reused:   ' || ln_reused_epe_areas);
    dbms_output.put_line('========================================');
end;
/