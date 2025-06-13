set serveroutput on;
declare
    -- cursor to get old data 
    cursor c_get_old_data
    is
        select  adt.id                                              as old_adt_id
        ,       cnt.cnt_id                                          as new_cnt_id
        ,       bld.cln_id                                          as new_cln_id
        ,       adt.auditcode                                       as code
        ,       adt.type                                            as type
        ,       adt.date1                                           as audit_date
        ,       adt.lastcontroldate                                 as last_control_date
        ,       case when adt.isactive = 1 then 'Y' else 'N' end    as active
        ,       case when adt.activate = 1 then 'Y' else 'N' end    as activate
        ,       case when adt.isdone = 1 then 'Y' else 'N' end      as audit_completed
        from    audits adt
        join    users_client  cnt on adt.nameclient_id = cnt.id
        join    buildings     bld on adt.locationclient_id = bld.id        
        where   adt.adt_id is null
        and     cnt.cnt_id is not null 
        and     bld.cln_id is not null
        ;
    --
    -- variables
    type t_old_data is table of c_get_old_data%rowtype;
    --
    lt_old_data t_old_data;
    ln_adt_id number;
    ln_apr_id number;
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
            ln_adt_id := null;
            ln_apr_id := null;
            --
            insert into icca_audits(    code                
                                    ,   type                
                                    ,   audit_date      
                                    ,   last_control_date    
                                    ,   cnt_id              
                                    ,   cln_id              
                                    ,   active              
                                    ,   activate            
                                    ,   audit_completed     
                                    ,   migrated_data       
                                ) values (
                                        lt_old_data(i).code
                                    ,   lt_old_data(i).type
                                    ,   lt_old_data(i).audit_date
                                    ,   lt_old_data(i).last_control_date
                                    ,   lt_old_data(i).new_cnt_id
                                    ,   lt_old_data(i).new_cln_id
                                    ,   lt_old_data(i).active
                                    ,   lt_old_data(i).activate
                                    ,   lt_old_data(i).audit_completed
                                    ,   'Y'
                                    )
                    returning id into ln_adt_id;
            --
            update  audits
            set     adt_id = ln_adt_id
            where   id = lt_old_data(i).old_adt_id
            ;
            dbms_output.put_line('Migrated audit: ' || lt_old_data(i).old_adt_id || ' to new adt_id: ' || ln_adt_id);
            --
            --
            -- insert audit auditor mapping
            for auditor in (    select  ln_adt_id       as new_adt_id
                                ,       pfr1.id         as new_pfr_id
                                ,       pfr.id          as old_pfr_id
                                from    auditauditor    apr
                                join    users_auditor   pfr on apr.auditorid = pfr.id
                                join    icca_users      usr on usr.id = pfr.usr_id
                                join    icca_performers pfr1 on pfr1.usr_id = usr.id
                                where   pfr.usr_id is not null
                                and     apr.auditid = lt_old_data(i).old_adt_id
            )
            loop
                --
                ln_apr_id := null;
                --
                dbms_output.put_line('Auditor: ' || auditor.old_pfr_id || ' - New Auditor: ' || auditor.new_pfr_id);
                insert into icca_adt_performers(    adt_id       
                                                ,   pfr_id       
                                                ,   migrated_data
                                            ) values (
                                                    auditor.new_adt_id
                                                ,   auditor.new_pfr_id
                                                ,   'Y'
                                            )
                                    returning id into ln_apr_id;
                --
                update  auditauditor
                set     apr_id      = ln_apr_id
                where   auditid     = lt_old_data(i).old_adt_id
                and     auditorid   = auditor.old_pfr_id
                ;                                  
                --
            end loop;
            --            
            --
        exception
            when others then
                -- log error
                dbms_output.put_line('Error migrating icca_audits for old_adt_id: ' || lt_old_data(i).old_adt_id || ' - ' || sqlerrm);
                dbms_output.put_line('Details: ' || 
                                     'Code: ' || lt_old_data(i).code || 
                                     ', Type: ' || lt_old_data(i).type || 
                                     ', Audit Date: ' || lt_old_data(i).audit_date || 
                                     ', Last Control Date: ' || lt_old_data(i).last_control_date ||
                                     ', Active: ' || lt_old_data(i).active ||
                                     ', Activate: ' || lt_old_data(i).activate ||
                                     ', Audit Completed: ' || lt_old_data(i).audit_completed);
                -- continue to next iteration
                continue;
        end;
    end loop;
    --
end;
/