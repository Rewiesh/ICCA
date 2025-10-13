declare
    -- cursor to get old data 
    cursor c_get_old_data
    is
        select  ekd.id              as old_ekd_id
        ,       ekd.Name            as name
        from    ErrorKinds ekd
        where   ekd.ekd_id is null
        ;
    --
    -- variables
    type t_old_data is table of c_get_old_data%rowtype;
    --
    lt_old_data t_old_data;
    ln_ekd_id number;
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
            ln_ekd_id := null;
            --
            insert into icca_error_kinds(   name         
                                        ,   migrated_data          
                                    ) values (
                                        lt_old_data(i).name
                                    ,   'Y'
                                    )
                    returning id into ln_ekd_id;
            --
            update  ErrorKinds
            set     ekd_id = ln_ekd_id
            where   id = lt_old_data(i).old_ekd_id
            ;
            --
        exception
            when others then
                -- log error
                dbms_output.put_line('Error migrating icca_error_kinds for old_ekd_id: ' || lt_old_data(i).old_ekd_id || ' - ' || sqlerrm);
                -- continue to next iteration
                continue;
        end;
    end loop;
    --
end;
/