set serveroutput on;
declare
    -- cursor to get old data 
    cursor c_get_old_data
    is
        select  fom.id                                                  as old_fom_id
        ,       adt.id                                                  as old_adt_id
        ,       pfr.id                                                  as old_pfr_id
        ,       adt.auditcode                                           as audit_code
        ,       adt.adt_id                                              as new_adt_id
        ,       pfr1.id                                                 as new_pfr_id
        ,       flr.flr_id                                              as new_flr_id
        ,       cat.cat_id                                              as new_cat_id
        ,       ara.ara_id                                              as new_ara_id
        ,       substr(fom.areacode,instr(fom.areacode, '.') + 1)       as area_number -- ruimtenummer
        ,       fom.counterelement                                      as element_count        
        ,       fom.faults                                              as error_count
        ,       fom.comments                                            as remark        
        ,       nvl(fom.date_, sysdate)                                 as form_date
        ,       fom.areacode                                            as migrated_area_code
        ,       substr(fom.areacode, 1, instr(fom.areacode, '-') - 1)   as verdieping 
        ,       substr(fom.areacode,instr(fom.areacode, '-') + 1,instr(fom.areacode, '.') - instr(fom.areacode, '-') - 1) as area
        from    forms             fom
        join    audits            adt on fom.auditid = adt.id
        join    floors            flr on fom.floorid = flr.id
        join    categories        cat on fom.categoryid = cat.id
        join    AreaDescriptions  ara on ara.ModuleId = 4 and upper(trim(ara.abbreviation)) = upper(substr(fom.areacode,instr(fom.areacode, '-') + 1,instr(fom.areacode, '.') - instr(fom.areacode, '-') - 1))
        join    users_auditor     pfr on fom.auditby_id = pfr.id
        join    icca_performers  pfr1 on pfr1.usr_id = pfr.usr_id
        where   substr(fom.areacode,instr(fom.areacode, '-') + 1,instr(fom.areacode, '.') - instr(fom.areacode, '-') - 1) is not null
        and     fom.fom_id is null
        and     adt.adt_id is not null
        and     pfr.usr_id is not null
--        and     adt.auditcode in ('13566')
        ;
    --
    -- variables
    type t_old_data is table of c_get_old_data%rowtype;
    --
    lt_old_data t_old_data;
    ln_fom_id number;
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
            ln_fom_id := null;
            --
            insert into icca_adt_forms(     adt_id          
                                        ,   pfr_id          
                                        ,   flr_id          
                                        ,   cat_id          
                                        ,   ara_id          
                                        ,   area_number     
                                        ,   element_count   
                                        ,   remark          
                                        ,   form_date       
                                        ,   error_count
                                        ,   migrated_area_code
                                        ,   migrated_data   
                                    ) values (
                                            lt_old_data(i).new_adt_id
                                        ,   lt_old_data(i).new_pfr_id
                                        ,   lt_old_data(i).new_flr_id
                                        ,   lt_old_data(i).new_cat_id
                                        ,   lt_old_data(i).new_ara_id
                                        ,   lt_old_data(i).area_number
                                        ,   lt_old_data(i).element_count
                                        ,   lt_old_data(i).remark
                                        ,   lt_old_data(i).form_date
                                        ,   lt_old_data(i).error_count
                                        ,   lt_old_data(i).migrated_area_code
                                        ,   'Y'
                                        )
                        returning id into ln_fom_id;
            --
            update  forms
            set     fom_id      = ln_fom_id
            where   id = lt_old_data(i).old_fom_id
            ;
            dbms_output.put_line('Migrated icca_adt_forms for old_fom_id: ' || lt_old_data(i).old_fom_id || ' to new fom_id: ' || ln_fom_id);
            --
--            commit;
            --
        exception
            when others then
                -- log error
                dbms_output.put_line('Error migrating icca_adt_forms for old_fom_id: ' || lt_old_data(i).old_fom_id || 
                                     ' - ' || sqlerrm);
                dbms_output.put_line('Details: ' || 'adt_id: ' || lt_old_data(i).old_adt_id || 
                                     ', pfr_id: ' || lt_old_data(i).old_pfr_id || 
                                     ', audit_code: ' || lt_old_data(i).audit_code || 
                                     ', area_number: ' || lt_old_data(i).area_number || 
                                     ', element_count: ' || lt_old_data(i).element_count || 
                                     ', error_count: ' || lt_old_data(i).error_count || 
                                     ', remark: ' || lt_old_data(i).remark);
                -- continue to next iteration
                continue;
        end;
    end loop;
    --
end;
/