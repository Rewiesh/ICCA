declare
    -- cursor to get old data 
    cursor c_get_old_data
    is
        select  ara.id                                          as old_ara_id
        ,       ara.Name                                        as name
        ,       ara.Abbreviation                                as code
        ,       case when ara.Active = 1 then 'Y' else 'N' end  as active
        from    AreaDescriptions ara
        where   1=1--ara.ara_id is null
        and     ara.ModuleId = 4
        ;
    --
    -- variables
    type t_old_data is table of c_get_old_data%rowtype;
    --
    lt_old_data t_old_data;
    ln_ara_id number;
    ln_aat_id number;
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
            ln_ara_id := null;
            ln_aat_id := null;
            --
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
            --
            update  AreaDescriptions
            set     ara_id = ln_ara_id
            where   id = lt_old_data(i).old_ara_id
            ;
            --
            for categorie in  ( select  ln_ara_id           as new_ara_id
                                ,       cat.cat_id          as new_cat_id
                                ,       cat.id              as old_cat_id
                                ,       AreaDescModuleId    as AreaDescModuleId
                                from    Category_AreaDescription  aat
                                join    Categories                cat on cat.id = aat.categoryid
                                where   aat.AreaDescId = lt_old_data(i).old_ara_id
                                and     cat.cat_id is not null
                                and     aat.AreaDescModuleId = 4
                            )
            loop
                --
                ln_aat_id := null;
                --
                insert into icca_ara_categories(    ara_id
                                                ,   cat_id
                                                ,   migrated_data
                                            ) values (
                                                    categorie.new_ara_id
                                                ,   categorie.new_cat_id
                                                ,   'Y'
                                            )
                                        returning id into ln_aat_id;
                --
                update  Category_AreaDescription
                set     aat_id      = ln_aat_id
                where   categoryid  = categorie.old_cat_id
                and     AreaDescId  = lt_old_data(i).old_ara_id
                and     AreaDescModuleId = categorie.AreaDescModuleId
                ;
                --
            end loop;
            --
        exception
            when others then
                -- log error
                dbms_output.put_line('Error migrating icca_areas for old_ara_id: ' || lt_old_data(i).old_ara_id || ' - ' || sqlerrm);
                -- continue to next iteration
                continue;
        end;
    end loop;
    --
end;
/