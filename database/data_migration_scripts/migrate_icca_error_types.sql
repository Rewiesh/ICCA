declare
    -- cursor to get old data 
    cursor c_get_old_data
    is
        select  ete.ErrorTypeId     as old_ete_id
        ,       ete.ErrorTypeValue  as name
        ,       ece.ece_id          as ece_id
        ,       ekd.ekd_id          as ekd_id
        from    ErrorType       ete
        join    ErrorCategories ece on ece.id = ete.ErrorCategoryId
        join    ErrorKinds      ekd on ekd.id = ete.ErrorKindId
        where   ete.ete_id is null
        ;
    --
    -- variables
    type t_old_data is table of c_get_old_data%rowtype;
    --    
    lt_old_data t_old_data;
    ln_ete_id number;
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
            ln_ete_id := null;
            --
            insert into icca_error_types(   name         
                                        ,   ece_id       
                                        ,   ekd_id       
                                        ,   migrated_data     
                                    ) values (
                                        lt_old_data(i).name
                                    ,   lt_old_data(i).ece_id
                                    ,   lt_old_data(i).ekd_id
                                    ,   'Y'
                                    )
                            returning id into ln_ete_id;
            --
            update  ErrorType
            set     ete_id = ln_ete_id
            where   ErrorTypeId = lt_old_data(i).old_ete_id
            ;
            --
        exception
            when others then
                -- log error
                dbms_output.put_line('Error migrating icca_error_types for old_ete_id: ' || lt_old_data(i).old_ete_id || ' - ' || sqlerrm);
                -- continue to next iteration
                continue;
        end;
    end loop;
    --
end;
/