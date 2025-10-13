declare
    cursor c_get_old_data
    is
        select  usr.id                                                                  as usr_id
        ,       cnt.id                                                                  as cnt_id
        ,       usr.username
        ,       ( select id from icca_user_groups where system_name = 'UGP_CLIENTS' )   as ugp_id
        ,       ( select id from icca_branches where name = 'Cleaning Industry' )       as bch_id
        ,       img.doc_id                                                              as logo_doc_id
        ,       'Y'                                                                     as active
        ,       'N'                                                                     as deleted
        ,       'Y'                                                                     as migrated_data
        ,       cnt.companyname                                                         as company_name                   
        ,       cnt.contactperson                                                       as contact_person
        ,       cnt.phone                                                               as phone_number
        ,       cnt.mobile                                                              as mobile_number
        ,       cnt.fax                                                                 as fax_number
        ,       cnt.StreetName                                                          as street_name
        ,       cnt.zipcode                                                             as zip_code
        ,       'Nederland'                                                             as country
        ,       cnt.city                                                                as city
        ,       cnt.state                                                               as province
        ,       case when cnt.ReportType = 0 then 'ICCA'
                    when cnt.ReportType = 1 then 'FASE_CONTROL'
                    when cnt.ReportType = 2 then 'BURO_HENNIE_DEKKER'
                    when cnt.ReportType = 3 then 'ICCA_ZONDER_CIJFER'
                    else null
                end                                                                     as audit_report_type
        ,       cnt.URLClientPortal                                                     as url_client_portal                  
        from    Users usr
        join    Users_Client cnt on cnt.id = usr.id
        left join images img on img.imageid = usr.ProfileImage
        -- where usr.usr_id is null
        -- and   cnt.cnt_id is null
        ;
    
    type t_old_data is table of c_get_old_data%rowtype;
    lt_old_data t_old_data;
    ln_usr_id number;
    ln_cnt_id number;
    ln_existing_usr_id number;
    ln_existing_cnt_id number;
    ln_eml_id number;
    ln_existing_eml_id number;
    
    ln_total_users number := 0;
    ln_new_users number := 0;
    ln_reused_users number := 0;
    ln_new_clients number := 0;
    ln_reused_clients number := 0;
    ln_new_emails number := 0;
    ln_reused_emails number := 0;
begin
    open    c_get_old_data;
    fetch   c_get_old_data bulk collect into lt_old_data;
    close   c_get_old_data;
    
    for i in 1 .. lt_old_data.count 
    loop
        begin
            ln_usr_id := null;
            ln_cnt_id := null;
            ln_existing_usr_id := null;
            ln_existing_cnt_id := null;
            
            -- ============================================
            -- STAP 1: USER MIGRATIE (met duplicate check)
            -- ============================================
            
            -- Check of user al gemigreerd is via oude tabel
            begin
                select usr_id 
                into ln_existing_usr_id
                from users
                where id = lt_old_data(i).usr_id
                and usr_id is not null;
            exception
                when no_data_found then
                    ln_existing_usr_id := null;
            end;
            
            -- Als nog niet gemigreerd, check op username
            if ln_existing_usr_id is null then
                begin
                    select  id 
                    into    ln_existing_usr_id
                    from    icca_users
                    where   upper(username) = upper(lt_old_data(i).username)
                    and     rownum = 1;
                exception
                    when no_data_found then
                        ln_existing_usr_id := null;
                end;
            end if;
            
            -- User aanmaken of hergebruiken
            if ln_existing_usr_id is not null then
                ln_usr_id := ln_existing_usr_id;
                ln_reused_users := ln_reused_users + 1;
                dbms_output.put_line('✓ Reusing user - usr_id: ' || ln_usr_id || ' for: ' || lt_old_data(i).username);
            else
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
                
                ln_new_users := ln_new_users + 1;
                dbms_output.put_line('✓ New user created - usr_id: ' || ln_usr_id || ' for: ' || lt_old_data(i).username);
            end if;
            
            -- Update oude users tabel (idempotent)
            update  users
            set     usr_id = ln_usr_id
            where   id = lt_old_data(i).usr_id;
            
            -- ============================================
            -- STAP 2: CLIENT MIGRATIE (met duplicate check)
            -- ============================================
            
            -- Check of client al gemigreerd is via oude tabel
            begin
                select cnt_id 
                into ln_existing_cnt_id
                from users_client
                where id = lt_old_data(i).cnt_id
                and cnt_id is not null;
            exception
                when no_data_found then
                    ln_existing_cnt_id := null;
            end;
            
            -- Als nog niet gemigreerd, check op company_name
            if ln_existing_cnt_id is null then
                begin
                    select  id 
                    into    ln_existing_cnt_id
                    from    icca_clients
                    where   upper(company_name) = upper(lt_old_data(i).company_name)
                    and     rownum = 1;
                exception
                    when no_data_found then
                        ln_existing_cnt_id := null;
                end;
            end if;
            
            -- Client aanmaken of hergebruiken
            if ln_existing_cnt_id is not null then
                ln_cnt_id := ln_existing_cnt_id;
                ln_reused_clients := ln_reused_clients + 1;
                dbms_output.put_line('✓ Reusing client - cnt_id: ' || ln_cnt_id || ' for: ' || lt_old_data(i).company_name);
            else
                insert into icca_clients(   usr_id              
                                        ,   bch_id              
                                        ,   company_name        
                                        ,   contact_person      
                                        ,   phone_number        
                                        ,   mobile_number       
                                        ,   country             
                                        ,   city                
                                        ,   province            
                                        ,   street_name         
                                        ,   fax_number          
                                        ,   logo_id             
                                        ,   zip_code            
                                        ,   audit_report_type   
                                        ,   url_client_portal   
                                        ,   migrated_data
                                    ) values (
                                            ln_usr_id
                                        ,   lt_old_data(i).bch_id
                                        ,   lt_old_data(i).company_name
                                        ,   lt_old_data(i).contact_person
                                        ,   lt_old_data(i).phone_number
                                        ,   lt_old_data(i).mobile_number
                                        ,   lt_old_data(i).country
                                        ,   lt_old_data(i).city
                                        ,   lt_old_data(i).province
                                        ,   lt_old_data(i).street_name
                                        ,   lt_old_data(i).fax_number
                                        ,   lt_old_data(i).logo_doc_id
                                        ,   lt_old_data(i).zip_code
                                        ,   lt_old_data(i).audit_report_type
                                        ,   lt_old_data(i).url_client_portal
                                        ,   lt_old_data(i).migrated_data
                                    )
                            returning id into ln_cnt_id;
                
                ln_new_clients := ln_new_clients + 1;
                dbms_output.put_line('✓ New client created - cnt_id: ' || ln_cnt_id || ' for: ' || lt_old_data(i).company_name);
            end if;
            
            -- Update oude users_client tabel (idempotent)
            update  users_client
            set     cnt_id = ln_cnt_id
            where   id = lt_old_data(i).cnt_id;
            
            -- ============================================
            -- STAP 3: EMAILS MIGRATIE (met duplicate check EN eml_id update)
            -- ============================================
            
            for email_rec in (
                select user_id, email_address
                from emails
                where user_id = lt_old_data(i).usr_id
            ) loop
                begin
                    ln_eml_id := null;
                    ln_existing_eml_id := null;
                    
                    -- Check of email al gemigreerd is via oude tabel
                    begin
                        select eml_id 
                        into ln_existing_eml_id
                        from emails
                        where user_id = email_rec.user_id
                        and email_address = email_rec.email_address
                        and eml_id is not null;
                    exception
                        when no_data_found then
                            ln_existing_eml_id := null;
                    end;
                    
                    -- Als nog niet gemigreerd, check in icca_usr_emails
                    if ln_existing_eml_id is null then
                        begin
                            select id
                            into ln_existing_eml_id
                            from icca_usr_emails
                            where usr_id = ln_usr_id
                            and email = email_rec.email_address
                            and rownum = 1;
                        exception
                            when no_data_found then
                                ln_existing_eml_id := null;
                        end;
                    end if;
                    
                    -- Email aanmaken of hergebruiken
                    if ln_existing_eml_id is not null then
                        ln_eml_id := ln_existing_eml_id;
                        ln_reused_emails := ln_reused_emails + 1;
                    else
                        insert into icca_usr_emails (usr_id, email)
                        values (ln_usr_id, email_rec.email_address)
                        returning id into ln_eml_id;
                        
                        ln_new_emails := ln_new_emails + 1;
                    end if;
                    
                    -- Update emails tabel met eml_id (idempotent)
                    update emails
                    set eml_id = ln_eml_id
                    where user_id = email_rec.user_id
                    and email_address = email_rec.email_address;
                    
                exception
                    when others then
                        dbms_output.put_line('  ⚠ Error migrating email: ' || email_rec.email_address || ' - ' || sqlerrm);
                end;
            end loop;
            
            ln_total_users := ln_total_users + 1;
            
        exception
            when others then
                dbms_output.put_line('✗ Error processing user: ' || lt_old_data(i).username || ' - ' || sqlerrm);
                dbms_output.put_line('  User ID: ' || lt_old_data(i).usr_id || ', Client ID: ' || lt_old_data(i).cnt_id);
                continue;
        end;
    end loop;
    
    commit;
    
    -- Summary rapport
    dbms_output.put_line('');
    dbms_output.put_line('========================================');
    dbms_output.put_line('MIGRATION SUMMARY');
    dbms_output.put_line('========================================');
    dbms_output.put_line('Total users processed:    ' || ln_total_users);
    dbms_output.put_line('  - New users created:    ' || ln_new_users);
    dbms_output.put_line('  - Existing users reused: ' || ln_reused_users);
    dbms_output.put_line('');
    dbms_output.put_line('Total clients:            ' || ln_total_users);
    dbms_output.put_line('  - New clients created:  ' || ln_new_clients);
    dbms_output.put_line('  - Existing clients reused: ' || ln_reused_clients);
    dbms_output.put_line('');
    dbms_output.put_line('Total emails:');
    dbms_output.put_line('  - New emails created:   ' || ln_new_emails);
    dbms_output.put_line('  - Existing emails reused: ' || ln_reused_emails);
    dbms_output.put_line('========================================');
end;
/