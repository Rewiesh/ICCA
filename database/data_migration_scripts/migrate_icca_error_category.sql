declare
    -- cursor to get old data 
    cursor c_get_old_data
    is
        select  ece.id              as old_ece_id
        ,       ece.Name            as name
        from    ErrorCategories ece
        where   ece.ece_id is null
        ;
    --
    -- variables
    type t_old_data is table of c_get_old_data%rowtype;
    --
    lt_old_data t_old_data;
    ln_ece_id number;
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
            ln_ece_id := null;
            --
            insert into icca_error_categories(  name         
                                            ,   migrated_data          
                                            ) values (
                                                lt_old_data(i).name
                                            ,   'Y'
                                            )
                            returning id into ln_ece_id;
            --
            update  ErrorCategories
            set     ece_id = ln_ece_id
            where   id = lt_old_data(i).old_ece_id
            ;
            --
        exception
            when others then
                -- log error
                dbms_output.put_line('Error migrating icca_error_categories for old_ece_id: ' || lt_old_data(i).old_ece_id || ' - ' || sqlerrm);
                -- continue to next iteration
                continue;
        end;
    end loop;
    --
end;
/