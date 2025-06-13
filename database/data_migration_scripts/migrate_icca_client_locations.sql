declare
    -- cursor to get old data CLIENT LOCATIONS
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
        from    Users_Client cnt
        join    buildings bld on bld.client_id = cnt.id
        where cnt.cnt_id is not null
        -- where cnt.companyname = 'ASKO'
        ;
    --
    -- variables
    type t_old_data is table of c_get_old_data%rowtype;
    --
    lt_old_data t_old_data;
    ln_usr_id number;
    ln_cnt_id number;
    ln_cln_id number;
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
            ln_cln_id := null;
            --
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
            --
            update  buildings
            set     cln_id = ln_cln_id
            where   id = lt_old_data(i).bld_id
            ;
            --
        exception
            when others then
                -- log error
                dbms_output.put_line('Error inserting data for client location: ' || lt_old_data(i).name || ' - ' || sqlerrm);
                dbms_output.put_line('Record details: ' || 
                    'cnt_id: ' || lt_old_data(i).cnt_id || 
                    ', name: ' || lt_old_data(i).name || 
                    ', location_size: ' || lt_old_data(i).location_size || 
                    ', contact_person: ' || lt_old_data(i).contact_person || 
                    ', country: ' || lt_old_data(i).country || 
                    ', city: ' || lt_old_data(i).city || 
                    ', province: ' || lt_old_data(i).province || 
                    ', street_name: ' || lt_old_data(i).street_name || 
                    ', email: ' || lt_old_data(i).email);
                -- Optionally, you can log this error to a table or file for further analysis
                -- continue with next record
                continue;
        end;
    end loop;
    --
end;
/