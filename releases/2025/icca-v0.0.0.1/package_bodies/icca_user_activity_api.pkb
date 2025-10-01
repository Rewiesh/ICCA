create or replace package body icca_user_activity_api 
as
    --
    -----------------------------------------------------------------------------------------
    --
    function f_audit_api_rec( p_username in varchar2 ) 
    return t_audit_api_rec 
    is
        v_data t_audit_api_rec;
    begin
        -- Aantal uitgevoerde audits
        select  count(*)
        into    v_data.performed_audits_count
        from    icca_audits     adt
        join    icca_performers pfr on pfr.id = adt.pfr_id
        join    icca_users      usr on usr.id = pfr.usr_id
        where   adt.audit_completed = 'Y'
        and     upper(usr.username) = upper(p_username);

        -- Laatste klant
        begin
            select  cnt.company_name
            into    v_data.last_client_name
            from    icca_audits adt
            join    icca_clients cnt on cnt.id = adt.cnt_id
            join    icca_performers pfr on pfr.id = adt.pfr_id
            join    icca_users usr on usr.id = pfr.usr_id
            where   adt.audit_completed = 'Y'
            and     upper(usr.username) = upper(p_username)
            order by adt.modified_date desc
            fetch first 1 row only;
        exception
            when no_data_found then
                v_data.last_client_name := null;
        end;

        -- Laatste locatie
        begin
            select  cln.name
            into    v_data.last_client_location_name
            from    icca_audits adt
            join    icca_clients cnt on cnt.id = adt.cnt_id
            join    icca_client_locations cln on cnt.id = cln.cnt_id
            join    icca_performers pfr on pfr.id = adt.pfr_id
            join    icca_users usr on usr.id = pfr.usr_id
            where   adt.audit_completed = 'Y'
            and     upper(usr.username) = upper(p_username)
            order by adt.modified_date desc
            fetch first 1 row only;
        exception
            when no_data_found then
                v_data.last_client_location_name := null;
        end;

        return v_data;
    end f_audit_api_rec;
    --
    -----------------------------------------------------------------------------------------
    --  
    function f_audit_api_json_obj( p_data in t_audit_api_rec ) 
    return json_object_t 
    is
        j json_object_t := json_object_t();
    begin
        j.put('performedAuditsCount', p_data.performed_audits_count);
        j.put('lastClientName', p_data.last_client_name);
        j.put('lastClientLocationName', p_data.last_client_location_name);
        return j;
    end f_audit_api_json_obj;
    --
    -----------------------------------------------------------------------------------------
    --  
    procedure p_get_data( p_username in varchar2 ) 
    is
        lt_audit_api_json_obj json_object_t;
        l_msg_clob            clob;
        l_chunk_size          constant pls_integer := 32000;
        l_offset              pls_integer := 1;
        l_total_length        pls_integer;
    begin
        -- Genereer JSON object op basis van data
        lt_audit_api_json_obj := f_audit_api_json_obj(f_audit_api_rec(p_username));

        if lt_audit_api_json_obj is not null 
        then
            l_msg_clob := lt_audit_api_json_obj.to_clob();
        else
            l_msg_clob := '{}';
        end if;

        -- Zet juiste response headers
        owa_util.mime_header('application/json', TRUE);
        htp.p(''); -- Scheiding tussen headers en body

        -- Schrijf CLOB in stukken
        l_total_length := dbms_lob.getlength(l_msg_clob);

        while l_offset <= l_total_length loop
            htp.p(dbms_lob.substr(l_msg_clob, l_chunk_size, l_offset));
            l_offset := l_offset + l_chunk_size;
        end loop;
    end p_get_data;
    --
    -----------------------------------------------------------------------------------------
    --
end icca_user_activity_api;
/
