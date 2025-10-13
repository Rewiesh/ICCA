declare
    cursor c_get_old_data
    is
        select  ara.id                                          as old_ara_id
        ,       ara.Name                                        as name
        ,       ara.Abbreviation                                as code
        ,       case when ara.Active = 1 then 'Y' else 'N' end  as active
        from    AreaDescriptions ara
        where   ara.ModuleId = 4
        -- and ara.ara_id is null
        ;
    
    type t_old_data is table of c_get_old_data%rowtype;
    lt_old_data t_old_data;
    ln_ara_id number;
    ln_aat_id number;
    ln_existing_ara_id number;
    ln_existing_aat_id number;
    
    ln_total_areas number := 0;
    ln_new_areas number := 0;
    ln_reused_areas number := 0;
    ln_new_ara_cats number := 0;
    ln_reused_ara_cats number := 0;
begin
    open    c_get_old_data;
    fetch   c_get_old_data bulk collect into lt_old_data;
    close   c_get_old_data;
    
    for i in 1 .. lt_old_data.count 
    loop
        begin
            ln_ara_id := null;
            ln_existing_ara_id := null;
            
            -- ============================================
            -- STAP 1: AREA MIGRATIE (met duplicate check)
            -- ============================================
            
            -- Check of area al gemigreerd is via oude tabel
            begin
                select ara_id 
                into ln_existing_ara_id
                from AreaDescriptions
                where id = lt_old_data(i).old_ara_id
                and ara_id is not null;
            exception
                when no_data_found then
                    ln_existing_ara_id := null;
            end;
            
            -- Als nog niet gemigreerd, check op naam of code
            if ln_existing_ara_id is null then
                begin
                    select  id 
                    into    ln_existing_ara_id
                    from    icca_areas
                    where   (upper(name) = upper(lt_old_data(i).name)
                            or upper(abbreviation) = upper(lt_old_data(i).code))
                    and     rownum = 1;
                exception
                    when no_data_found then
                        ln_existing_ara_id := null;
                end;
            end if;
            
            -- Area aanmaken of hergebruiken
            if ln_existing_ara_id is not null then
                ln_ara_id := ln_existing_ara_id;
                ln_reused_areas := ln_reused_areas + 1;
                dbms_output.put_line('✓ Reusing area - ara_id: ' || ln_ara_id || ' for: ' || lt_old_data(i).name || ' (' || lt_old_data(i).code || ')');
            else
                insert into icca_areas(     name      
                                        ,   abbreviation  
                                        ,   active   
                                        ,   migrated_data          
                                    ) values (  
                                            lt_old_data(i).name
                                        ,   lt_old_data(i).code
                                        ,   lt_old_data(i).active
                                        ,   'Y'
                                    )
                                returning id into ln_ara_id;
                
                ln_new_areas := ln_new_areas + 1;
                dbms_output.put_line('✓ New area created - ara_id: ' || ln_ara_id || ' for: ' || lt_old_data(i).name || ' (' || lt_old_data(i).code || ')');
            end if;
            
            -- Update oude AreaDescriptions tabel (idempotent)
            update  AreaDescriptions
            set     ara_id = ln_ara_id
            where   id = lt_old_data(i).old_ara_id;
            
            -- ============================================
            -- STAP 2: AREA-CATEGORY MAPPING (met duplicate check)
            -- ============================================
            
            for categorie in (
                select  ln_ara_id           as new_ara_id
                ,       cat.cat_id          as new_cat_id
                ,       cat.id              as old_cat_id
                ,       aat.AreaDescId      as old_area_id
                ,       aat.AreaDescModuleId as area_desc_module_id
                from    Category_AreaDescription aat
                join    Categories cat on cat.id = aat.categoryid
                where   aat.AreaDescId = lt_old_data(i).old_ara_id
                and     cat.cat_id is not null
                and     aat.AreaDescModuleId = 4
            ) loop
                begin
                    ln_aat_id := null;
                    ln_existing_aat_id := null;
                    
                    -- Check of mapping al gemigreerd is via oude tabel
                    begin
                        select aat_id 
                        into ln_existing_aat_id
                        from Category_AreaDescription
                        where categoryid = categorie.old_cat_id
                        and AreaDescId = categorie.old_area_id
                        and AreaDescModuleId = categorie.area_desc_module_id
                        and aat_id is not null;
                    exception
                        when no_data_found then
                            ln_existing_aat_id := null;
                    end;
                    
                    -- Als nog niet gemigreerd, check in icca_ara_categories
                    if ln_existing_aat_id is null then
                        begin
                            select id
                            into ln_existing_aat_id
                            from icca_ara_categories
                            where ara_id = categorie.new_ara_id
                            and cat_id = categorie.new_cat_id
                            and rownum = 1;
                        exception
                            when no_data_found then
                                ln_existing_aat_id := null;
                        end;
                    end if;
                    
                    -- Mapping aanmaken of hergebruiken
                    if ln_existing_aat_id is not null then
                        ln_aat_id := ln_existing_aat_id;
                        ln_reused_ara_cats := ln_reused_ara_cats + 1;
                    else
                        insert into icca_ara_categories(    ara_id
                                                        ,   cat_id
                                                        ,   migrated_data
                                                    ) values (
                                                            categorie.new_ara_id
                                                        ,   categorie.new_cat_id
                                                        ,   'Y'
                                                    )
                                                returning id into ln_aat_id;
                        
                        ln_new_ara_cats := ln_new_ara_cats + 1;
                    end if;
                    
                    -- Update Category_AreaDescription tabel met aat_id (idempotent)
                    update  Category_AreaDescription
                    set     aat_id = ln_aat_id
                    where   categoryid = categorie.old_cat_id
                    and     AreaDescId = categorie.old_area_id
                    and     AreaDescModuleId = categorie.area_desc_module_id;
                    
                exception
                    when others then
                        dbms_output.put_line('  ⚠ Error migrating area-category mapping: ' || sqlerrm);
                end;
            end loop;
            
            ln_total_areas := ln_total_areas + 1;
            
        exception
            when others then
                dbms_output.put_line('✗ Error processing area: ' || lt_old_data(i).name || ' - ' || sqlerrm);
                dbms_output.put_line('  old_ara_id: ' || lt_old_data(i).old_ara_id);
                continue;
        end;
    end loop;
    
    commit;
    
    -- Summary rapport
    dbms_output.put_line('');
    dbms_output.put_line('========================================');
    dbms_output.put_line('AREA MIGRATION SUMMARY');
    dbms_output.put_line('========================================');
    dbms_output.put_line('Total areas processed:          ' || ln_total_areas);
    dbms_output.put_line('  - New areas created:          ' || ln_new_areas);
    dbms_output.put_line('  - Existing areas reused:      ' || ln_reused_areas);
    dbms_output.put_line('');
    dbms_output.put_line('Area-Category mappings:');
    dbms_output.put_line('  - New mappings created:       ' || ln_new_ara_cats);
    dbms_output.put_line('  - Existing mappings reused:   ' || ln_reused_ara_cats);
    dbms_output.put_line('========================================');
end;
/