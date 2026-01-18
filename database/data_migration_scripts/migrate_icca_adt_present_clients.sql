declare
    cursor c_get_old_data is
        select distinct adt.adt_id, adt.presentclient
        from audits2 adt
        where adt.adt_id is not null
          and adt.presentclient is not null;

    type t_old_data is table of c_get_old_data%rowtype;
    lt_old_data t_old_data;

    l_exists number;
begin
    open c_get_old_data;
    fetch c_get_old_data bulk collect into lt_old_data;
    close c_get_old_data;

    for i in 1 .. lt_old_data.count loop
        for j in (
            select trim(regexp_substr(lt_old_data(i).presentclient, '[^,]+', 1, level)) as single_name
            from dual
            connect by regexp_substr(lt_old_data(i).presentclient, '[^,]+', 1, level) is not null
        ) loop
            if j.single_name is not null and length(j.single_name) > 0 then
                begin
                    -- check of record al bestaat
                    select case when exists (
                        select 1
                        from icca_adt_present_clients x
                        where x.adt_id = lt_old_data(i).adt_id
                          and trim(x.name) = j.single_name
                    ) then 1 else 0 end
                    into l_exists
                    from dual;

                    if l_exists = 0 then
                        insert into icca_adt_present_clients(adt_id, name, migrated_data)
                        values (lt_old_data(i).adt_id, j.single_name, 'Y');
                    end if;

                exception
                    when others then
                        dbms_output.put_line('Error migrating present client for adt_id ' || lt_old_data(i).adt_id || ': ' || sqlerrm);
                        dbms_output.put_line('Client Name: ' || j.single_name);
                end;
            else
                dbms_output.put_line('Skipping empty client name for adt_id ' || lt_old_data(i).adt_id);
            end if;
        end loop;
    end loop;
end;
/
