set serveroutput on;
declare
    -- cursor to get old data 
    cursor c_get_old_data
    is
        with w_errortype
        as  (   select  errortypeid
                ,       errortypevalue
                ,       ete_id
                from    ErrorType
                group by errortypeid
                ,       errortypevalue
                ,       ete_id
        )
        select  frr.errorelementid      as frr_pk_id
        ,       fom.fom_id              as new_fom_id
        ,       ete.ete_id              as new_ete_id
        ,       epe.epe_id              as new_epe_id
        ,       frr.count               as error_count
        ,       frr.logbook             as log_book_remark
        ,       frr.technicalaspects    as technical_aspects_remark
        from    formerrorelement  frr
        join    forms             fom on fom.id = frr.formid
        join    audits            adt on fom.auditid = adt.id
        join    w_errortype       ete on ete.errortypeid = frr.errortypeid
        join    ElementType       epe on epe.elementtypeid = frr.elementid
        where   frr.for_id is null
        and     fom.fom_id is not null
        -- and     adt.auditcode in ('13569')
        ;
    --
    -- variables
    type t_old_data is table of c_get_old_data%rowtype;
    --
    lt_old_data t_old_data;
    ln_for_id number;
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
            ln_for_id := null;
            --
            insert into icca_fom_errors(    fom_id                      
                                        ,   ete_id                      
                                        ,   epe_id                      
                                        ,   error_count                 
                                        ,   log_book_remark             
                                        ,   technical_aspects_remark    
                                        -- ,   log_book_image_id           
                                        -- ,   technical_aspects_image_id  
                                        ,   migrated_data               
                                    ) values (
                                            lt_old_data(i).new_fom_id
                                        ,   lt_old_data(i).new_ete_id
                                        ,   lt_old_data(i).new_epe_id
                                        ,   lt_old_data(i).error_count
                                        ,   lt_old_data(i).log_book_remark
                                        ,   lt_old_data(i).technical_aspects_remark
                                        ,   'Y'
                                        )
                        returning id into ln_for_id;
            --
            update  formerrorelement
            set     for_id          = ln_for_id
            where   errorelementid  = lt_old_data(i).frr_pk_id
            ;
            dbms_output.put_line('Migrated icca_fom_errors for frr_pk_id: ' || lt_old_data(i).frr_pk_id || 
                                 ' to new for_id: ' || ln_for_id);
            --
--            commit;
            --
        exception
            when others then
                -- log error
                dbms_output.put_line('Error migrating icca_fom_errors for frr_pk_id: ' || lt_old_data(i).frr_pk_id || 
                                     ' - ' || sqlerrm);
                dbms_output.put_line('Details: ' || 'fom_id: ' || lt_old_data(i).new_fom_id || 
                                     ', ete_id: ' || lt_old_data(i).new_ete_id || 
                                     ', epe_id: ' || lt_old_data(i).new_epe_id || 
                                     ', error_count: ' || lt_old_data(i).error_count || 
                                     ', log_book_remark: ' || lt_old_data(i).log_book_remark || 
                                     ', technical_aspects_remark: ' || lt_old_data(i).technical_aspects_remark);
                -- continue to next iteration
                continue;
        end;
    end loop;
    --
end;
/