declare
    cursor c_get_old_data
    is
        select  flr.id              as old_flr_id
        ,       flr.FloorName       as name
        ,       flr.FloorNameAbv    as code    
        from    Floors flr
        where   flr.flr_id is null
        ;
    
    type t_old_data is table of c_get_old_data%rowtype;
    lt_old_data t_old_data;
    ln_flr_id number;
    ln_existing_flr_id number;
begin
    open    c_get_old_data;
    fetch   c_get_old_data bulk collect into lt_old_data;
    close   c_get_old_data;
    
    for i in 1 .. lt_old_data.count 
    loop
        begin
            ln_flr_id := null;
            ln_existing_flr_id := null;
            
            -- **CHECK: Bestaat deze combinatie al in de nieuwe tabel?**
            begin
                select  id 
                into    ln_existing_flr_id
                from    icca_floors
                where   name = lt_old_data(i).name
                and     code = lt_old_data(i).code
                and     rownum = 1;  -- voor zekerheid
            exception
                when no_data_found then
                    ln_existing_flr_id := null;
            end;
            
            -- Als record al bestaat, gebruik die flr_id
            if ln_existing_flr_id is not null then
                ln_flr_id := ln_existing_flr_id;
                dbms_output.put_line('Duplicate found - reusing flr_id: ' || ln_flr_id || ' for: ' || lt_old_data(i).name);
            else
                -- Nieuw record aanmaken
                insert into icca_floors(    name         
                                        ,   code         
                                        ,   migrated_data          
                                        ) values (
                                            lt_old_data(i).name
                                        ,   lt_old_data(i).code
                                        ,   'Y'
                                        )
                        returning id into ln_flr_id;
                
                dbms_output.put_line('New floor created - flr_id: ' || ln_flr_id || ' for: ' || lt_old_data(i).name);
            end if;
            
            -- Update oude record met flr_id
            update  Floors
            set     flr_id = ln_flr_id
            where   id = lt_old_data(i).old_flr_id;
            
        exception
            when others then
                dbms_output.put_line('Error migrating floor: ' || lt_old_data(i).old_flr_id || ' - ' || sqlerrm);
                dbms_output.put_line('Floor Name: ' || lt_old_data(i).name || ' - Code: ' || lt_old_data(i).code);
                continue;
        end;
    end loop;
    
    commit;
end;
/