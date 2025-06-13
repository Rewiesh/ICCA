declare
    -- cursor to get old data 
    cursor c_get_old_data
    is
        select  ket.id                                                  as old_ket_id
        ,       ket.ElementLabel                                        as name
        ,       case when ket.ElementStatus = 1 then 'Y' else 'N' end   as active
        from    Element ket
        -- where   ket.ket_id is null
        ;
    --
    -- variables
    type t_old_data is table of c_get_old_data%rowtype;
    --
    lt_old_data t_old_data;
    ln_ket_id number;
    ln_kcn_id number;
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
            ln_ket_id := null;
            ln_kcn_id := null;
            --
            insert into icca_kpi_elementen(     name      
                                            ,   active     
                                            ,   migrated_data          
                                        ) values (
                                                lt_old_data(i).name
                                            ,   lt_old_data(i).active
                                            ,   'Y'
                                        )
                                    returning id into ln_ket_id;
            --
            update  Element
            set     ket_id = ln_ket_id
            where   id = lt_old_data(i).old_ket_id
            ;
            --
            for element in  (   select  ln_ket_id       as new_ket_id
                                ,       cnt.cnt_id      as new_cnt_id
                                ,       cnt.id          as old_cnt_id
                                ,       'Y'             as migrated_data
                                from    ElementClient kcn  
                                join    users_client  cnt on cnt.id = kcn.idclient
                                where   kcn.idelement = lt_old_data(i).old_ket_id
                                and     cnt.cnt_id is not null
                            )
            loop
                --
                ln_kcn_id := null;
                --
                insert into icca_ket_clients(   ket_id
                                            ,   cnt_id
                                            ,   migrated_data
                                        ) values (
                                                element.new_ket_id
                                            ,   element.new_cnt_id
                                            ,   element.migrated_data
                                        )
                                    returning id into ln_kcn_id;
                --
                update  ElementClient
                set     kcn_id      = ln_kcn_id
                where   idelement   = lt_old_data(i).old_ket_id
                and     idclient    = element.old_cnt_id
                ;
                --
            end loop;
            --
        exception
            when others then
                -- log error
                dbms_output.put_line('Error migrating icca_kpi_elementen for old_ket_id: ' || lt_old_data(i).old_ket_id || ' - ' || sqlerrm);
                -- continue to next iteration
                continue;
        end;
    end loop;
    --
end;
/