set serveroutput on;
declare
    -- cursor to get old data 
    cursor c_get_old_data
    is
        select  ant.idaudit                 as old_adt_id
        ,       ant.idelement               as old_elm_id
        ,       adt.adt_id                  as new_adt_id
        ,       elm.ket_id                  as new_ket_id
        ,       null                        as new_kcn_id
        ,       elm.elementlabel            as element_label
        ,       trim(sts.ElementStatusValueCode)  as element_value
        ,       ant.elementauditcomment     as element_comment
        from    elementaudit        ant
        join    audits              adt on adt.id = ant.idaudit
        join    element             elm on elm.id = ant.idelement
        -- join    elementclient       kcn on kcn.idelement = ant.idelement
        join    ElementStatusValue  sts on sts.id = ant.elementauditstatus
        where   adt.adt_id is not null
        and     elm.ket_id is not null
        -- and     kcn.kcn_id is not null
--        and     adt.auditcode = '10215'
        ;
    --
    -- variables
    type t_old_data is table of c_get_old_data%rowtype;
    --
    lt_old_data t_old_data;
    ln_ant_id number;
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
            ln_ant_id := null;
            --
            insert into icca_adt_kpi_elements(      kcn_id          
                                                ,   adt_id          
                                                ,   ket_id          
                                                ,   element_label   
                                                ,   element_value   
                                                ,   element_comment 
                                                ,   migrated_data      
                                            ) values (
                                                    lt_old_data(i).new_kcn_id
                                                ,   lt_old_data(i).new_adt_id
                                                ,   lt_old_data(i).new_ket_id
                                                ,   lt_old_data(i).element_label
                                                ,   lt_old_data(i).element_value
                                                ,   lt_old_data(i).element_comment
                                                ,   'Y'
                                                )
                                returning id into ln_ant_id;
            --
            update  elementaudit
            set     ant_id      = ln_ant_id
            where   idelement   = lt_old_data(i).old_elm_id
            and     idaudit     = lt_old_data(i).old_adt_id
            ;
            dbms_output.put_line('Migrated icca_adt_kpi_elements for old_adt_id: ' || lt_old_data(i).old_adt_id || ' and old_elm_id: ' || lt_old_data(i).old_elm_id || ' to new ant_id: ' || ln_ant_id);
            --
            commit;
            --
        exception
            when others then
                -- log error
                dbms_output.put_line('Error migrating icca_adt_kpi_elements for old_adt_id: ' || lt_old_data(i).old_adt_id || 
                                     ' and old_elm_id: ' || lt_old_data(i).old_elm_id || 
                                     ' - ' || sqlerrm);
                dbms_output.put_line('Details: ' || 'kcn_id: ' || lt_old_data(i).new_kcn_id || 
                                     ', adt_id: ' || lt_old_data(i).new_adt_id || 
                                     ', ket_id: ' || lt_old_data(i).new_ket_id || 
                                     ', element_label: ' || lt_old_data(i).element_label || 
                                     ', element_value: ' || lt_old_data(i).element_value || 
                                     ', element_comment: ' || lt_old_data(i).element_comment);
                -- continue to next iteration
                continue;
        end;
    end loop;
    --
end;
/