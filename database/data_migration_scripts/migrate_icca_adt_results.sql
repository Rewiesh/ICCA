set serveroutput on;
declare
    -- cursor to get old data 
    cursor c_get_old_data
    is
        select  ars.idaudit                                         as old_adt_id
        ,       ars.idcategory                                      as old_cat_id
        ,       adt.adt_id                                          as new_adt_id
        ,       cat.cat_id                                          as new_cat_id
        ,       ars.counterelements                                 as counter_elements
        ,       ars.approvelimit                                    as approve_limit
        ,       ars.rating                                          as score
        ,       case when ars.IsSuficient = 1 then 'Y' else 'N' end as is_sufficient
        from    ResultAuditCategory ars
        join    audits              adt on ars.idaudit = adt.id
        join    categories          cat on ars.idcategory = cat.id
        where   ars.ars_id is null
        and     adt.adt_id is not null
        and     cat.cat_id is not null
        ;
    --
    -- variables
    type t_old_data is table of c_get_old_data%rowtype;
    --
    lt_old_data t_old_data;
    ln_ars_id number;
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
            ln_ars_id := null;
            --
            insert into icca_adt_results(   adt_id                      
                                        ,   cat_id              
                                        ,   counter_elements    
                                        ,   approve_limit       
                                        ,   score               
                                        ,   is_sufficient                                                      
                                        ,   migrated_data               
                                    ) values (
                                            lt_old_data(i).new_adt_id
                                        ,   lt_old_data(i).new_cat_id
                                        ,   lt_old_data(i).counter_elements
                                        ,   lt_old_data(i).approve_limit
                                        ,   lt_old_data(i).score
                                        ,   lt_old_data(i).is_sufficient
                                        ,   'Y'
                                        )
                        returning id into ln_ars_id;
            --
            update  ResultAuditCategory
            set     ars_id      = ln_ars_id
            where   idaudit     = lt_old_data(i).old_adt_id
            and     idcategory  = lt_old_data(i).old_cat_id
            ;
            --
            dbms_output.put_line('Migrated icca_adt_results for old_adt_id: ' || lt_old_data(i).old_adt_id || 
                                 ' - new_ars_id: ' || ln_ars_id || 
                                 ', new_adt_id: ' || lt_old_data(i).new_adt_id || 
                                 ', new_cat_id: ' || lt_old_data(i).new_cat_id || 
                                 ', counter_elements: ' || lt_old_data(i).counter_elements || 
                                 ', approve_limit: ' || lt_old_data(i).approve_limit || 
                                 ', score: ' || lt_old_data(i).score || 
                                 ', is_sufficient: ' || lt_old_data(i).is_sufficient);
            --
--            commit;
            --
        exception
            when others then
                -- log error
                dbms_output.put_line('Error migrating icca_adt_results for old_adt_id: ' || lt_old_data(i).old_adt_id || 
                                     ' - ' || sqlerrm);
                dbms_output.put_line('Details: ' || 'new_adt_id: ' || lt_old_data(i).new_adt_id || 
                                     ', new_cat_id: ' || lt_old_data(i).new_cat_id || 
                                     ', counter_elements: ' || lt_old_data(i).counter_elements || 
                                     ', approve_limit: ' || lt_old_data(i).approve_limit || 
                                     ', score: ' || lt_old_data(i).score || 
                                     ', is_sufficient: ' || lt_old_data(i).is_sufficient);
                -- continue to next iteration
                continue;
        end;
    end loop;
    --
end;
/