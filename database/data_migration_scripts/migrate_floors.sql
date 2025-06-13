declare
    -- cursor to get old data CLIENT LOCATIONS
    cursor c_get_old_data
    is
        select  flr.id              as old_flr_id
        ,       flr.FloorName       as name
        ,       flr.FloorNameAbv    as code    
        from    Floors flr
        where   flr.flr_id is null
        ;
    --
    -- variables
    type t_old_data is table of c_get_old_data%rowtype;
    --
    lt_old_data t_old_data;
    ln_flr_id number;
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
            ln_flr_id := null;
            --
            insert into icca_floors(    name         
                                    ,   code         
                                    ,   migrated_data          
                                    ) values (
                                        lt_old_data(i).name
                                    ,   lt_old_data(i).code
                                    ,   'Y'
                                    )
                    returning id into ln_flr_id;
            --
            update  Floors
            set     flr_id = ln_flr_id
            where   id = lt_old_data(i).old_flr_id
            ;
            --
        exception
            when others then
                -- log error
                dbms_output.put_line('Error migrating floor: ' || lt_old_data(i).old_flr_id || ' - ' || sqlerrm);
                dbms_output.put_line('Floor Name: ' || lt_old_data(i).name || ' - Code: ' || lt_old_data(i).code);
                -- continue to next iteration
                continue;
        end;
    end loop;
    --
end;
/