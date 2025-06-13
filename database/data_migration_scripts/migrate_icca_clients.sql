declare
    -- cursor to get old data from Users and Users_Client tables
    cursor c_get_old_data
    is
        select  usr.id                                                                  as usr_id
        ,       cnt.id                                                                  as cnt_id
        ,       usr.username
        ,       ( select id from icca_user_groups where system_name = 'UGP_CLIENTS' )   as ugp_id
        ,       ( select id from icca_branches where name = 'Cleaning Industry' )       as bch_id
        ,       'Y'                                                                     as active
        ,       'N'                                                                     as deleted
        ,       'Y'                                                                     as migrated_data
        --
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
        ,      cnt.URLClientPortal                                                    as url_client_portal                  
        from    Users usr
        join    Users_Client cnt on cnt.id = usr.id
        -- where usr.usr_id is null
        -- and   cnt.cnt_id is null
        ;
    --
    -- variables
    type t_old_data is table of c_get_old_data%rowtype;
    --
    lt_old_data t_old_data;
    ln_usr_id number;
    ln_cnt_id number;
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
                                    ,   null -- logo_id
                                    ,   lt_old_data(i).zip_code
                                    ,   lt_old_data(i).audit_report_type
                                    ,   lt_old_data(i).url_client_portal
                                    ,   lt_old_data(i).migrated_data
                                )
                            returning id into ln_cnt_id;
            --
            update  users_client
            set     cnt_id = ln_cnt_id
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