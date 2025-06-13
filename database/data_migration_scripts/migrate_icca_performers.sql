declare
    -- cursor to get old data from Users and Users_Administrator tables
    cursor c_get_old_data
    is
        select  usr.id                                                                  as usr_id
        ,       cnt.id                                                                  as cnt_id
        ,       usr.username
        ,       ( select id from icca_user_groups where system_name = 'UGP_PERFORMERS') as ugp_id
        ,       ( select id from icca_branches where name = 'Cleaning Industry' )       as bch_id
        ,       'Y'                                                                     as active
        ,       'N'                                                                     as deleted
        ,       'Y'                                                                     as migrated_data
        --  
        ,       usr.firstname                                                           as first_name
        ,       usr.lastname                                                            as last_name
        ,       cnt.phone                                                               as phone_number  
        ,       cnt.mobile                                                              as mobile_number
        ,       case when pty.performertypes_id = 1 then 'Y' else 'N' end               as is_auditor
        ,       case when pty.performertypes_id = 2 then 'Y' else 'N' end               as is_project_leader 
        from    Users usr
        join    Users_Auditor cnt on cnt.id = usr.id
        left join  TypeOfPerformers pty on pty.Performers_Id = cnt.id
        -- where cnt.usr_id is null
        -- and usr.username = 'dhrpvanl'
        -- and   cnt.cnt_id is null
--        fetch first 1 rows only -- limit the number of rows fetched for performance reasons
        ;
    --
    -- variables
    type t_old_data is table of c_get_old_data%rowtype;
    --
    lt_old_data t_old_data;
    ln_usr_id number;
    ln_cnt_id number;
    ln_pfr_id number;
    ln_pnt_id number;
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
            ln_usr_id := null;
            ln_cnt_id := null;
            ln_pfr_id := null;
            ln_pnt_id := null;
            --
            insert into icca_users( username
                                ,   ugp_id
                                ,   bch_id
                                ,   active
                                ,   deleted
                                ,   migrated_data
                                ) values (
                                    lt_old_data(i).username
                                ,   lt_old_data(i).ugp_id
                                ,   lt_old_data(i).bch_id
                                ,   lt_old_data(i).active
                                ,   lt_old_data(i).deleted
                                ,   lt_old_data(i).migrated_data
                                ) 
            returning id into ln_usr_id;
            --
            update  users
            set     usr_id = ln_usr_id
            where   id = lt_old_data(i).usr_id
            ;
            --
            insert into icca_performers(    usr_id              
                                        ,   is_auditor          
                                        ,   is_project_leader   
                                        ,   first_name          
                                        ,   last_name           
                                        ,   phone_number        
                                        ,   mobile_number
                                        ,   migrated_data
                                    ) values (
                                            ln_usr_id
                                        ,   'Y' -- assuming all users are auditors
                                        ,   'N' -- assuming not all users are project leaders
                                        ,   lt_old_data(i).first_name
                                        ,   lt_old_data(i).last_name
                                        ,   lt_old_data(i).phone_number
                                        ,   lt_old_data(i).mobile_number
                                        ,   lt_old_data(i).migrated_data
                                        )
                                    returning id into ln_pfr_id;
            --
            update  Users_Auditor
            set     usr_id = ln_usr_id
            where   id = lt_old_data(i).cnt_id
            ;
            --
            insert into icca_usr_emails (   usr_id
                                        ,   email
                                        )
                                    select  ln_usr_id
                                    ,       eml.email_address -- assuming a default email format
                                    from    emails eml
                                    where   user_id = lt_old_data(i).usr_id
                                    ;
            --  
            --
            for pfr in  (   select  old.auditor_id
                            ,       old.client_id
                            ,       k.cnt_id
                            from    client_auditor old
                            join    users_client k on k.id = old.client_id
                            where   old.auditor_id = lt_old_data(i).cnt_id
                            and     k.cnt_id is not null
                        )
            loop
                --
                ln_pnt_id := null;
                --
                insert into icca_pfr_clients(   pfr_id
                                            ,   cnt_id     
                                            )
                                    values (    ln_pfr_id
                                            ,   pfr.cnt_id
                                            )
                                    returning id into ln_pnt_id;
                --
                update client_auditor
                set    pnt_id       = ln_pnt_id
                where  auditor_id   = pfr.auditor_id
                and    client_id    = pfr.client_id
                ;
            end loop;

            --
        exception
            when others then
                -- log error
                dbms_output.put_line('Error inserting data for user: ' || lt_old_data(i).username || ' - ' || sqlerrm);
                dbms_output.put_line('User ID: ' || lt_old_data(i).usr_id || ', Client ID: ' || lt_old_data(i).cnt_id);
                -- continue with next record
                continue;
        end;
    end loop;
    --
end;
/