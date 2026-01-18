declare
    cursor c_get_old_data
    is
        select  cnt.cnt_id                                          as cnt_id
        ,       bld.id                                              as bld_id
        ,       bld.name                                            as name       
        ,       bld.size1                                           as location_size
        ,       'Nederland'                                         as country
        ,       bld.region                                          as province
        ,       bld.city                                            as city
        ,       bld.address                                         as street_name
        ,       bld.contact_person                                  as contact_person
        ,       case when bld.activate = 1 then 'Y' else 'N' end    as active
        ,       bld.email                                           as email
        ,       'Y'                                                 as migrated_data
        from    Users_Client2 cnt
        join    buildings2 bld on bld.client_id = cnt.id
        where   cnt.cnt_id is not null
        -- and bld.cln_id is null
        ;
    
    type t_old_data is table of c_get_old_data%rowtype;
    lt_old_data t_old_data;
    ln_cln_id number;
    ln_existing_cln_id number;
    
    ln_total_locations number := 0;
    ln_new_locations number := 0;
    ln_reused_locations number := 0;
begin
    open    c_get_old_data;
    fetch   c_get_old_data bulk collect into lt_old_data;
    close   c_get_old_data;
    
    for i in 1 .. lt_old_data.count 
    loop
        begin
            ln_cln_id := null;
            ln_existing_cln_id := null;
            
            -- ============================================
            -- CLIENT LOCATION MIGRATIE (met duplicate check)
            -- ============================================
            
            -- Check of location al gemigreerd is via oude tabel
            begin
                select cln_id 
                into ln_existing_cln_id
                from buildings2
                where id = lt_old_data(i).bld_id
                and cln_id is not null;
            exception
                when no_data_found then
                    ln_existing_cln_id := null;
            end;
            
            -- Als nog niet gemigreerd, check op unieke combinatie
            -- (cnt_id + street_name + city is uniek voor een locatie)
            if ln_existing_cln_id is null then
                begin
                    select  id 
                    into    ln_existing_cln_id
                    from    icca_client_locations
                    where   cnt_id = lt_old_data(i).cnt_id
                    and     upper(nvl(street_name, 'NULL')) = upper(nvl(lt_old_data(i).street_name, 'NULL'))
                    and     upper(nvl(city, 'NULL')) = upper(nvl(lt_old_data(i).city, 'NULL'))
                    and     rownum = 1;
                exception
                    when no_data_found then
                        ln_existing_cln_id := null;
                end;
            end if;
            
            -- Location aanmaken of hergebruiken
            if ln_existing_cln_id is not null then
                ln_cln_id := ln_existing_cln_id;
                ln_reused_locations := ln_reused_locations + 1;
                dbms_output.put_line('✓ Reusing location - cln_id: ' || ln_cln_id || ' for: ' || lt_old_data(i).name || ' (' || lt_old_data(i).city || ')');
            else
                insert into icca_client_locations(  cnt_id          
                                                ,   name            
                                                ,   location_size   
                                                ,   contact_person  
                                                ,   country         
                                                ,   city            
                                                ,   province        
                                                ,   street_name     
                                                ,   email           
                                                ,   active          
                                                ,   migrated_data
                                            ) values (
                                                lt_old_data(i).cnt_id
                                            ,   lt_old_data(i).name
                                            ,   lt_old_data(i).location_size
                                            ,   lt_old_data(i).contact_person
                                            ,   lt_old_data(i).country
                                            ,   lt_old_data(i).city
                                            ,   lt_old_data(i).province
                                            ,   lt_old_data(i).street_name
                                            ,   lt_old_data(i).email
                                            ,   lt_old_data(i).active
                                            ,   lt_old_data(i).migrated_data
                                            )
                                    returning id into ln_cln_id;
                
                ln_new_locations := ln_new_locations + 1;
                dbms_output.put_line('✓ New location created - cln_id: ' || ln_cln_id || ' for: ' || lt_old_data(i).name || ' (' || lt_old_data(i).city || ')');
            end if;
            
            -- Update oude buildings tabel (idempotent)
            update  buildings2
            set     cln_id = ln_cln_id
            where   id = lt_old_data(i).bld_id;
            
            ln_total_locations := ln_total_locations + 1;
            
        exception
            when others then
                dbms_output.put_line('✗ Error processing client location: ' || lt_old_data(i).name || ' - ' || sqlerrm);
                dbms_output.put_line('  cnt_id: ' || lt_old_data(i).cnt_id || ', bld_id: ' || lt_old_data(i).bld_id);
                continue;
        end;
    end loop;
    
    commit;
    
    -- Summary rapport
    dbms_output.put_line('');
    dbms_output.put_line('========================================');
    dbms_output.put_line('CLIENT LOCATION MIGRATION SUMMARY');
    dbms_output.put_line('========================================');
    dbms_output.put_line('Total locations processed:      ' || ln_total_locations);
    dbms_output.put_line('  - New locations created:      ' || ln_new_locations);
    dbms_output.put_line('  - Existing locations reused:  ' || ln_reused_locations);
    dbms_output.put_line('========================================');
end;
/