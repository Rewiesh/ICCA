declare
    cursor c_get_old_data
    is
        select  usr.id                                                                  as usr_id
        ,       aud.id                                                                  as aud_id
        ,       usr.username
        ,       ( select id from icca_user_groups where system_name = 'UGP_PERFORMERS') as ugp_id
        ,       ( select id from icca_branches where name = 'Cleaning Industry' )       as bch_id
        ,       img.doc_id                                                              as profile_pic_id
        ,       'Y'                                                                     as active
        ,       'N'                                                                     as deleted
        ,       'Y'                                                                     as migrated_data
        ,       usr.firstname                                                           as first_name
        ,       usr.lastname                                                            as last_name
        ,       aud.phone                                                               as phone_number  
        ,       aud.mobile                                                              as mobile_number
        ,       case when exists (
                    select 1 from TypeOfPerformers 
                    where Performers_Id = aud.id 
                    and performertypes_id = 1
                ) then 'Y' else 'N' end                                                 as is_auditor
        ,       case when exists (
                    select 1 from TypeOfPerformers 
                    where Performers_Id = aud.id 
                    and performertypes_id = 2
                ) then 'Y' else 'N' end                                                 as is_project_leader 
        from    Users usr
        join    Users_Auditor aud on aud.id = usr.id
        left join images img on img.imageid = usr.ProfileImage
        where aud.usr_id is null
        ;
    
    type t_old_data is table of c_get_old_data%rowtype;
    lt_old_data t_old_data;
    ln_usr_id number;
    ln_pfr_id number;
    ln_pnt_id number;
    ln_existing_usr_id number;
    ln_existing_pfr_id number;
    ln_existing_pnt_id number;
    ln_eml_id number;
    ln_existing_eml_id number;
    
    ln_total_users number := 0;
    ln_new_users number := 0;
    ln_reused_users number := 0;
    ln_new_performers number := 0;
    ln_reused_performers number := 0;
    ln_new_emails number := 0;
    ln_reused_emails number := 0;
    ln_new_relations number := 0;
    ln_reused_relations number := 0;
begin
    open    c_get_old_data;
    fetch   c_get_old_data bulk collect into lt_old_data;
    close   c_get_old_data;
    
    for i in 1 .. lt_old_data.count 
    loop
        begin
            ln_usr_id := null;
            ln_pfr_id := null;
            ln_existing_usr_id := null;
            ln_existing_pfr_id := null;
            
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
            -- STAP 2: PERFORMER MIGRATIE (met duplicate check)
            -- ============================================
            
            -- Check of performer al gemigreerd is via oude tabel
            begin
                select usr_id 
                into ln_existing_pfr_id
                from Users_Auditor
                where id = lt_old_data(i).aud_id
                and usr_id is not null;
                
                -- Als usr_id is gevuld, haal de pfr_id op
                if ln_existing_pfr_id is not null then
                    select id
                    into ln_existing_pfr_id
                    from icca_performers
                    where usr_id = ln_existing_pfr_id
                    and rownum = 1;
                end if;
            exception
                when no_data_found then
                    ln_existing_pfr_id := null;
            end;
            
            -- Als nog niet gemigreerd, check op usr_id (1 performer per user)
            if ln_existing_pfr_id is null then
                begin
                    select  id 
                    into    ln_existing_pfr_id
                    from    icca_performers
                    where   usr_id = ln_usr_id
                    and     rownum = 1;
                exception
                    when no_data_found then
                        ln_existing_pfr_id := null;
                end;
            end if;
            
            -- Performer aanmaken of hergebruiken
            if ln_existing_pfr_id is not null then
                ln_pfr_id := ln_existing_pfr_id;
                ln_reused_performers := ln_reused_performers + 1;
                dbms_output.put_line('✓ Reusing performer - pfr_id: ' || ln_pfr_id || ' for: ' || lt_old_data(i).first_name || ' ' || lt_old_data(i).last_name);
            else
                insert into icca_performers(    usr_id              
                                            ,   is_auditor          
                                            ,   is_project_leader   
                                            ,   first_name          
                                            ,   last_name           
                                            ,   phone_number        
                                            ,   mobile_number
                                            ,   migrated_data
                                            ,   profile_pic_id
                                        ) values (
                                                ln_usr_id
                                            ,   lt_old_data(i).is_auditor
                                            ,   lt_old_data(i).is_project_leader
                                            ,   lt_old_data(i).first_name
                                            ,   lt_old_data(i).last_name
                                            ,   lt_old_data(i).phone_number
                                            ,   lt_old_data(i).mobile_number
                                            ,   lt_old_data(i).migrated_data
                                            ,   lt_old_data(i).profile_pic_id
                                            )
                                        returning id into ln_pfr_id;
                
                ln_new_performers := ln_new_performers + 1;
                dbms_output.put_line('✓ New performer created - pfr_id: ' || ln_pfr_id || ' for: ' || lt_old_data(i).first_name || ' ' || lt_old_data(i).last_name);
            end if;
            
            -- Update oude Users_Auditor tabel (idempotent)
            update  Users_Auditor
            set     usr_id = ln_usr_id
            where   id = lt_old_data(i).aud_id;
            
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
            
            -- ============================================
            -- STAP 4: PERFORMER-CLIENT RELATIES (met duplicate check)
            -- ============================================
            
            for pfr in (
                select  ca.auditor_id
                ,       ca.client_id
                ,       uc.cnt_id
                from    client_auditor ca
                join    users_client uc on uc.id = ca.client_id
                where   ca.auditor_id = lt_old_data(i).aud_id
                and     uc.cnt_id is not null
            ) loop
                begin
                    ln_pnt_id := null;
                    ln_existing_pnt_id := null;
                    
                    -- Check of relatie al gemigreerd is via oude tabel
                    begin
                        select pnt_id 
                        into ln_existing_pnt_id
                        from client_auditor
                        where auditor_id = pfr.auditor_id
                        and client_id = pfr.client_id
                        and pnt_id is not null;
                    exception
                        when no_data_found then
                            ln_existing_pnt_id := null;
                    end;
                    
                    -- Als nog niet gemigreerd, check in icca_pfr_clients
                    if ln_existing_pnt_id is null then
                        begin
                            select id
                            into ln_existing_pnt_id
                            from icca_pfr_clients
                            where pfr_id = ln_pfr_id
                            and cnt_id = pfr.cnt_id
                            and rownum = 1;
                        exception
                            when no_data_found then
                                ln_existing_pnt_id := null;
                        end;
                    end if;
                    
                    -- Relatie aanmaken of hergebruiken
                    if ln_existing_pnt_id is not null then
                        ln_pnt_id := ln_existing_pnt_id;
                        ln_reused_relations := ln_reused_relations + 1;
                    else
                        insert into icca_pfr_clients(pfr_id, cnt_id)
                        values (ln_pfr_id, pfr.cnt_id)
                        returning id into ln_pnt_id;
                        
                        ln_new_relations := ln_new_relations + 1;
                    end if;
                    
                    -- Update client_auditor tabel met pnt_id (idempotent)
                    update client_auditor
                    set pnt_id = ln_pnt_id
                    where auditor_id = pfr.auditor_id
                    and client_id = pfr.client_id;
                    
                exception
                    when others then
                        dbms_output.put_line('  ⚠ Error migrating performer-client relation: ' || sqlerrm);
                end;
            end loop;
            
            ln_total_users := ln_total_users + 1;
            
        exception
            when others then
                dbms_output.put_line('✗ Error processing user: ' || lt_old_data(i).username || ' - ' || sqlerrm);
                dbms_output.put_line('  User ID: ' || lt_old_data(i).usr_id || ', Auditor ID: ' || lt_old_data(i).aud_id);
                continue;
        end;
    end loop;
    
    commit;
    
    -- Summary rapport
    dbms_output.put_line('');
    dbms_output.put_line('========================================');
    dbms_output.put_line('PERFORMER MIGRATION SUMMARY');
    dbms_output.put_line('========================================');
    dbms_output.put_line('Total users processed:        ' || ln_total_users);
    dbms_output.put_line('  - New users created:        ' || ln_new_users);
    dbms_output.put_line('  - Existing users reused:    ' || ln_reused_users);
    dbms_output.put_line('');
    dbms_output.put_line('Total performers:             ' || ln_total_users);
    dbms_output.put_line('  - New performers created:   ' || ln_new_performers);
    dbms_output.put_line('  - Existing performers reused: ' || ln_reused_performers);
    dbms_output.put_line('');
    dbms_output.put_line('Total emails:');
    dbms_output.put_line('  - New emails created:       ' || ln_new_emails);
    dbms_output.put_line('  - Existing emails reused:   ' || ln_reused_emails);
    dbms_output.put_line('');
    dbms_output.put_line('Performer-Client relations:');
    dbms_output.put_line('  - New relations created:    ' || ln_new_relations);
    dbms_output.put_line('  - Existing relations reused: ' || ln_reused_relations);
    dbms_output.put_line('========================================');
end;
/