begin
    -- Define template for the module
    ords.define_template(   p_module_name => 'api'
                        ,   p_pattern     => 'postAudits/'
                        );
end;
/
begin
    -- Handler for the endpoint
    ords.define_handler(    p_module_name   => 'api'
                        ,   p_pattern       => 'postAudits/'
                        ,   p_method        => 'POST'
                        ,   p_source_type   => ords.source_type_plsql
                        ,   p_source        => q'[declare
    v_audit_data  blob := :body;
    ln_ige_id     number;
    v_username    varchar2(100);
    ln_pfr_id     number;
    ln_audit_id   number;
begin
    -- get user
    v_username := :username;

    begin
        -- get the pfr_id from the username
        select  pfr.id
        into    ln_pfr_id
        from    icca_users      usr
        join    icca_performers pfr on pfr.usr_id = usr.id
        where   upper(username) = upper(v_username)
        fetch first row only;
    exception
    when others then
            -- geen performer gevonden, dus geen audit
            ln_pfr_id := null;
    end;

    -- set application context voor audit triggers
    dbms_session.set_identifier(v_username);

    -- store incoming message for logging purposes
    icca_incoming_msg.p_store_incoming_message(
        p_pfr_id       => ln_pfr_id,
        p_api_method   => 'POST',
        p_api_endpoint => 'api/postAudits/ ', 
        p_msg          => apex_util.blob_to_clob(v_audit_data, 'UTF-8'),
        po_ige_id      => ln_ige_id
    );

    -- process ingekomen audit
    icca_audit_post_api.p_msg_handler( ln_ige_id, ln_audit_id );

    -- return the ID as JSON
    owa_util.status_line (200, '', false);
    owa_util.mime_header ('application/json', true);
    htp.prn('{"id": "' || ln_audit_id || '"}');

end;
]'
                        );

    -- parameter: username
    ords.define_parameter(    p_module_name         => 'api'
                          ,   p_pattern             => 'postAudits/'
                          ,   p_method              => 'POST'
                          ,   p_name                => 'X-Username'
                          ,   p_bind_variable_name  => 'username'
                          ,   p_source_type         => 'HEADER'
                          ,   p_param_type          => 'STRING'
                          );

    commit;
end;
/

