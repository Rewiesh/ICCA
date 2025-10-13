declare
    cursor c_get_old_data
    is
        select  ete.ErrorTypeId     as old_ete_id
        ,       ete.ErrorTypeValue  as name
        ,       ece.ece_id          as ece_id
        ,       ekd.ekd_id          as ekd_id
        from    ErrorType       ete
        join    ErrorCategories ece on ece.id = ete.ErrorCategoryId
        join    ErrorKinds      ekd on ekd.id = ete.ErrorKindId
        where   ete.ete_id is null
        ;
    
    type t_old_data is table of c_get_old_data%rowtype;
    lt_old_data t_old_data;
    ln_ete_id number;
    ln_existing_ete_id number;
begin
    open    c_get_old_data;
    fetch   c_get_old_data bulk collect into lt_old_data;
    close   c_get_old_data;
    
    for i in 1 .. lt_old_data.count 
    loop
        begin
            ln_ete_id := null;
            ln_existing_ete_id := null;
            
            -- **CHECK: Bestaat deze combinatie al in de nieuwe tabel?**
            begin
                select  id 
                into    ln_existing_ete_id
                from    icca_error_types
                where   name = lt_old_data(i).name
                and     ece_id = lt_old_data(i).ece_id
                and     ekd_id = lt_old_data(i).ekd_id
                and     rownum = 1;
            exception
                when no_data_found then
                    ln_existing_ete_id := null;
            end;
            
            -- Als record al bestaat, gebruik die ete_id
            if ln_existing_ete_id is not null then
                ln_ete_id := ln_existing_ete_id;
                dbms_output.put_line('Duplicate found - reusing ete_id: ' || ln_ete_id || ' for: ' || lt_old_data(i).name);
            else
                -- Nieuw record aanmaken
                insert into icca_error_types(   name         
                                            ,   ece_id       
                                            ,   ekd_id       
                                            ,   migrated_data     
                                        ) values (
                                            lt_old_data(i).name
                                        ,   lt_old_data(i).ece_id
                                        ,   lt_old_data(i).ekd_id
                                        ,   'Y'
                                        )
                                returning id into ln_ete_id;
                
                dbms_output.put_line('New error type created - ete_id: ' || ln_ete_id || ' for: ' || lt_old_data(i).name);
            end if;
            
            -- Update oude record met ete_id
            update  ErrorType
            set     ete_id = ln_ete_id
            where   ErrorTypeId = lt_old_data(i).old_ete_id;
            
        exception
            when others then
                dbms_output.put_line('Error migrating icca_error_types for old_ete_id: ' || lt_old_data(i).old_ete_id || ' - ' || sqlerrm);
                dbms_output.put_line('ErrorType: ' || lt_old_data(i).name || ' - ece_id: ' || lt_old_data(i).ece_id || ' - ekd_id: ' || lt_old_data(i).ekd_id);
                continue;
        end;
    end loop;
    
    commit;
end;
/