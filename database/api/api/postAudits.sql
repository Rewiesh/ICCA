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
begin
    -- get user
    v_username := :username; 

    -- set application context voor audit triggers
    dbms_session.set_identifier(v_username);

    -- store incoming message for logging purposes
    icca_incoming_msg.p_store_incoming_message(
        p_api_method   => 'POST',
        p_api_endpoint => 'api/postAudits/ ',
        p_msg          => apex_util.blob_to_clob(v_audit_data, 'UTF-8'),
        po_ige_id      => ln_ige_id
    );

    -- process ingekomen audit
    icca_audit_post_api.p_msg_handler( ln_ige_id );

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

                                                    