declare
    cursor c_get_old_data
    is
        select  id                                              as old_cat_id
        ,       CategoryName                                    as name
        ,       case when isfixed = 1 then 'Y' else 'N' end     as fixed_value
        ,       'Y'                                             as active
        ,       'Y'                                             as migrated_data
        from    Categories
        -- where cat_id is null
        ;
    
    type t_old_data is table of c_get_old_data%rowtype;
    lt_old_data t_old_data;
    ln_cat_id number;
    ln_clt_id number;
    ln_clm_id number;
    ln_existing_cat_id number;
    ln_existing_clt_id number;
    ln_existing_clm_id number;
    
    ln_total_categories number := 0;
    ln_new_categories number := 0;
    ln_reused_categories number := 0;
    ln_new_cat_clients number := 0;
    ln_reused_cat_clients number := 0;
    ln_new_cat_limits number := 0;
    ln_reused_cat_limits number := 0;
begin
    open    c_get_old_data;
    fetch   c_get_old_data bulk collect into lt_old_data;
    close   c_get_old_data;
    
    for i in 1 .. lt_old_data.count 
    loop
        begin
            ln_cat_id := null;
            ln_existing_cat_id := null;
            
            -- ============================================
            -- STAP 1: CATEGORY MIGRATIE (met duplicate check)
            -- ============================================
            
            -- Check of category al gemigreerd is via oude tabel
            begin
                select cat_id 
                into ln_existing_cat_id
                from Categories
                where id = lt_old_data(i).old_cat_id
                and cat_id is not null;
            exception
                when no_data_found then
                    ln_existing_cat_id := null;
            end;
            
            -- Als nog niet gemigreerd, check op naam
            if ln_existing_cat_id is null then
                begin
                    select  id 
                    into    ln_existing_cat_id
                    from    icca_categories
                    where   upper(name) = upper(lt_old_data(i).name)
                    and     rownum = 1;
                exception
                    when no_data_found then
                        ln_existing_cat_id := null;
                end;
            end if;
            
            -- Category aanmaken of hergebruiken
            if ln_existing_cat_id is not null then
                ln_cat_id := ln_existing_cat_id;
                ln_reused_categories := ln_reused_categories + 1;
                dbms_output.put_line('✓ Reusing category - cat_id: ' || ln_cat_id || ' for: ' || lt_old_data(i).name);
            else
                insert into icca_categories (   name            
                                            ,   fixed_value     
                                            ,   active          
                                            ,   migrated_data   
                                        ) values (
                                                lt_old_data(i).name
                                            ,   lt_old_data(i).fixed_value
                                            ,   lt_old_data(i).active
                                            ,   lt_old_data(i).migrated_data
                                    )
                                returning id into ln_cat_id;
                
                ln_new_categories := ln_new_categories + 1;
                dbms_output.put_line('✓ New category created - cat_id: ' || ln_cat_id || ' for: ' || lt_old_data(i).name);
            end if;
            
            -- Update oude Categories tabel (idempotent)
            update  Categories
            set     cat_id = ln_cat_id
            where   id = lt_old_data(i).old_cat_id;
            
            -- ============================================
            -- STAP 2: CATEGORY-CLIENT MAPPING (met duplicate check)
            -- ============================================
            
            for client in (
                select  ln_cat_id       as new_cat_id
                ,       cnt.cnt_id      as cnt_id
                ,       cct.client_id   as old_client_id
                ,       cct.category_id as old_category_id
                from    categories cat
                join    client_category2 cct on cct.category_id = cat.id
                join    Users_Client2 cnt on cnt.id = cct.client_id
                where   cat.id = lt_old_data(i).old_cat_id
                and     cnt.cnt_id is not null
            ) loop
                begin
                    ln_clt_id := null;
                    ln_existing_clt_id := null;
                    
                    -- Check of mapping al gemigreerd is via oude tabel
                    begin
                        select clt_id 
                        into ln_existing_clt_id
                        from client_category
                        where category_id = client.old_category_id
                        and client_id = client.old_client_id
                        and clt_id is not null;
                    exception
                        when no_data_found then
                            ln_existing_clt_id := null;
                    end;
                    
                    -- Als nog niet gemigreerd, check in icca_cat_clients
                    if ln_existing_clt_id is null then
                        begin
                            select id
                            into ln_existing_clt_id
                            from icca_cat_clients
                            where cat_id = client.new_cat_id
                            and cnt_id = client.cnt_id
                            and rownum = 1;
                        exception
                            when no_data_found then
                                ln_existing_clt_id := null;
                        end;
                    end if;
                    
                    -- Mapping aanmaken of hergebruiken
                    if ln_existing_clt_id is not null then
                        ln_clt_id := ln_existing_clt_id;
                        ln_reused_cat_clients := ln_reused_cat_clients + 1;
                    else
                        insert into icca_cat_clients(   cat_id       
                                                    ,   cnt_id       
                                                    ,   migrated_data
                                                ) values (
                                                        client.new_cat_id
                                                    ,   client.cnt_id
                                                    ,   'Y'
                                                )
                                        returning id into ln_clt_id;
                        
                        ln_new_cat_clients := ln_new_cat_clients + 1;
                    end if;
                    
                    -- Update client_category tabel met clt_id (idempotent)
                    update  client_category
                    set     clt_id = ln_clt_id
                    where   category_id = client.old_category_id
                    and     client_id = client.old_client_id;
                    
                exception
                    when others then
                        dbms_output.put_line('  ⚠ Error migrating category-client mapping: ' || sqlerrm);
                end;
            end loop;
            
            -- ============================================
            -- STAP 3: CATEGORY LIMITS (met duplicate check)
            -- ============================================
            
            for limit in (
                select  con.id                      as old_clm_id
                ,       ln_cat_id                   as new_cat_id
                ,       bld.cbe_id                  as cbe_id
                ,       con.minimun_size_range      as min_size_range
                ,       con.maximun_size_range      as max_size_range
                ,       con.approved_limit          as approve_limit
                from    ConstantSizeCategory con
                join    BuildingSizeScale bld on bld.id = con.building_size_scale_id
                where   con.category_id = lt_old_data(i).old_cat_id
                and     bld.cbe_id is not null
            ) loop
                begin
                    ln_clm_id := null;
                    ln_existing_clm_id := null;
                    
                    -- Check of limit al gemigreerd is via oude tabel
                    begin
                        select clm_id 
                        into ln_existing_clm_id
                        from ConstantSizeCategory
                        where id = limit.old_clm_id
                        and clm_id is not null;
                    exception
                        when no_data_found then
                            ln_existing_clm_id := null;
                    end;
                    
                    -- Als nog niet gemigreerd, check in icca_cat_limits
                    if ln_existing_clm_id is null then
                        begin
                            select id
                            into ln_existing_clm_id
                            from icca_cat_limits
                            where cat_id = limit.new_cat_id
                            and cbe_id = limit.cbe_id
                            and min_size_range = limit.min_size_range
                            and max_size_range = limit.max_size_range
                            and rownum = 1;
                        exception
                            when no_data_found then
                                ln_existing_clm_id := null;
                        end;
                    end if;
                    
                    -- Limit aanmaken of hergebruiken
                    if ln_existing_clm_id is not null then
                        ln_clm_id := ln_existing_clm_id;
                        ln_reused_cat_limits := ln_reused_cat_limits + 1;
                    else
                        insert into icca_cat_limits(    cat_id          
                                                    ,   cbe_id          
                                                    ,   min_size_range  
                                                    ,   max_size_range  
                                                    ,   approve_limit   
                                                    ,   migrated_data
                                                ) values (
                                                        limit.new_cat_id
                                                    ,   limit.cbe_id
                                                    ,   limit.min_size_range
                                                    ,   limit.max_size_range
                                                    ,   limit.approve_limit
                                                    ,   'Y'
                                                )
                                            returning id into ln_clm_id;
                        
                        ln_new_cat_limits := ln_new_cat_limits + 1;
                    end if;
                    
                    -- Update ConstantSizeCategory tabel met clm_id (idempotent)
                    update  ConstantSizeCategory
                    set     clm_id = ln_clm_id
                    where   id = limit.old_clm_id;
                    
                exception
                    when others then
                        dbms_output.put_line('  ⚠ Error migrating category limit: ' || sqlerrm);
                end;
            end loop;
            
            ln_total_categories := ln_total_categories + 1;
            
        exception
            when others then
                dbms_output.put_line('✗ Error processing category: ' || lt_old_data(i).name || ' - ' || sqlerrm);
                dbms_output.put_line('  old_cat_id: ' || lt_old_data(i).old_cat_id);
                continue;
        end;
    end loop;
    
    commit;
    
    -- Summary rapport
    dbms_output.put_line('');
    dbms_output.put_line('========================================');
    dbms_output.put_line('CATEGORY MIGRATION SUMMARY');
    dbms_output.put_line('========================================');
    dbms_output.put_line('Total categories processed:     ' || ln_total_categories);
    dbms_output.put_line('  - New categories created:     ' || ln_new_categories);
    dbms_output.put_line('  - Existing categories reused: ' || ln_reused_categories);
    dbms_output.put_line('');
    dbms_output.put_line('Category-Client mappings:');
    dbms_output.put_line('  - New mappings created:       ' || ln_new_cat_clients);
    dbms_output.put_line('  - Existing mappings reused:   ' || ln_reused_cat_clients);
    dbms_output.put_line('');
    dbms_output.put_line('Category limits:');
    dbms_output.put_line('  - New limits created:         ' || ln_new_cat_limits);
    dbms_output.put_line('  - Existing limits reused:     ' || ln_reused_cat_limits);
    dbms_output.put_line('========================================');
end;
/