declare
    -- cursor to get old data 
    cursor c_get_old_data
    is
        select  epe.elementtypeid       as old_epe_id
        ,       epe.elementtypevalue    as name
        from    ElementType epe
        ;
    --
    -- variables
    type t_old_data is table of c_get_old_data%rowtype;
    --
    lt_old_data t_old_data;
    ln_epe_id number;
    ln_era_id number;
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
            ln_epe_id := null;
            ln_era_id := null;
            --
            insert into icca_elementtypes(  name      
                                        ,   migrated_data          
                                    ) values (
                                            lt_old_data(i).name
                                        ,   'Y'
                                    )
                                returning id into ln_epe_id;
            --
            update  ElementType
            set     epe_id = ln_epe_id
            where   ElementTypeId = lt_old_data(i).old_epe_id
            ;
            --
            for element in  (   select  ln_epe_id       as new_epe_id
                                ,       ara.id          as old_ara_id
                                ,       ara.ara_id      as new_ara_id
                                from    AreaDescription_ElementType era
                                join    AreaDescriptions            ara on ara.id = era.AreaDescId
                                where   era.elementtypeid = lt_old_data(i).old_epe_id
                                and     ara.ara_id is not null
                            )
            loop
                --
                ln_era_id := null;
                --
                insert into icca_epe_areas( epe_id
                                        ,   ara_id
                                        ,   migrated_data
                                    ) values (
                                            element.new_epe_id
                                        ,   element.new_ara_id
                                        ,   'Y'
                                    )
                                returning id into ln_era_id;
                --
                update  AreaDescription_ElementType
                set     era_id          = ln_era_id
                where   elementtypeid   = lt_old_data(i).old_epe_id
                and     AreaDescId      = element.old_ara_id
                ;
                --
            end loop;
            --
        exception
            when others then
                -- log error
                dbms_output.put_line('Error migrating icca_kpi_elementen for old_epe_id: ' || lt_old_data(i).old_epe_id || ' - ' || sqlerrm);
                -- continue to next iteration
                continue;
        end;
    end loop;
    --
end;
/