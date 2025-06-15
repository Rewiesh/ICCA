declare
    -- cursor to get old data 
    cursor c_get_old_data
    is
        select  *
        from    ratingvalue
        ;
    --
    -- variables
    type t_old_data is table of c_get_old_data%rowtype;
    --
    lt_old_data t_old_data;
    ln_sce_id   number;
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
            ln_sce_id := null;
            --
            insert into icca_scores(    score         
                                    ,   migrated_data     
                                ) values (
                                    lt_old_data(i).ratingvalue
                                ,   'Y'
                                )
                        returning id into ln_sce_id;
            --
            update  ratingvalue
            set     sce_id  = ln_sce_id
            where   id      = lt_old_data(i).id
            ;
            --
        exception
            when others then
                -- log error
                dbms_output.put_line('Error migrating icca_scores for id: ' || lt_old_data(i).id || ' - ' || sqlerrm);
                -- continue to next iteration
                continue;
        end;
    end loop;
    --
end;
/