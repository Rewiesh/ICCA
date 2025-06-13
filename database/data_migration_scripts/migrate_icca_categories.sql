declare
    -- cursor to get old data from Users and Users_Administrator tables
    cursor c_get_old_data
    is
        select  id      as old_cat_id
        ,       CategoryName    as name
        ,       case when isfixed = 1 then 'Y' else 'N' end as fixed_value
        ,       'Y'     as active
        ,       'Y'     as migrated_data
        from    Categories
        where   cat_id is null
        -- fetch first 1 rows only
        ;
    --
    -- variables
    type t_old_data is table of c_get_old_data%rowtype;
    --
    lt_old_data t_old_data;
    ln_cat_id number;
    ln_clt_id number;
    ln_clm_id number;
begin
    --
    -- get old data
    open    c_get_old_data;
    fetch   c_get_old_data bulk collect into lt_old_data;
    close   c_get_old_data;
    --
    for i in 1 .. lt_old_data.count 
    loop
        begin
            ln_cat_id := null;
            ln_clt_id := null;
            ln_clm_id := null;
            --
            -- insert into icca_categories
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
            --
            update  Categories
            set     cat_id  = ln_cat_id
            where   id      = lt_old_data(i).old_cat_id
            ;
            --
            -- insert category client mapping
            for client in ( select  ln_cat_id       as new_cat_id
                            ,       cnt.cnt_id      as cnt_id
                            ,       cct.client_id   as old_client_id
                            from    categories cat
                            join    client_category cct on cct.category_id = cat.id
                            join    Users_Client    cnt on cnt.id = cct.client_id
                            where   cat.id = lt_old_data(i).old_cat_id
                            and     cnt.cnt_id is not null
            )
            loop
                --
                ln_clt_id := null;
                --
                insert into icca_cat_clients(   cat_id       
                                            ,   cnt_id       
                                            ,   migrated_data
                                        ) values (
                                                client.new_cat_id
                                            ,   client.cnt_id
                                            ,   'Y'
                                        )
                                returning id into ln_clt_id;
                --
                update  client_category
                set     clt_id = ln_clt_id
                where   category_id = lt_old_data(i).old_cat_id
                and     client_id = client.old_client_id
                ;                                  
                --
            end loop;
            --
            -- insert category constants
            for limit in (  select  con.id                  as old_clm_Id
                            ,       ln_cat_id               as new_cat_id
                            ,       bld.cbe_id              as cbe_id
                            ,       con.minimun_size_range  as min_size_range
                            ,       con.maximun_size_range  as max_size_range
                            ,       con.approved_limit       as approve_limit
                            from    ConstantSizeCategory    con
                            join    BuildingSizeScale       bld on bld.id = con.building_size_scale_id
                            where   con.category_id = lt_old_data(i).old_cat_id
                            and     con.category_id is not null
            )
            loop
                --
                ln_clm_id := null;
                --
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
                --  
                update  ConstantSizeCategory
                set     clm_id = ln_clm_id
                where   id = limit.old_clm_Id            
                ;
            end loop;
            --
        exception
            when others then
                -- log error
                dbms_output.put_line('Error inserting data for category: ' || lt_old_data(i).name || ' - ' || sqlerrm);
                dbms_output.put_line('Record details: ' || 
                    'old_cat_id: ' || lt_old_data(i).old_cat_id || 
                    ', name: ' || lt_old_data(i).name || 
                    ', fixed_value: ' || lt_old_data(i).fixed_value || 
                    ', active: ' || lt_old_data(i).active);
                -- continue with next record
                continue;
        end;
    end loop;
    --
end;
/