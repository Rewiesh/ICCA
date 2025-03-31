begin
    -- maak een modules aan voor authentication
    ords.define_module(   p_module_name     => 'api'
                      ,   p_base_path       => 'api/'
                      ,   p_items_per_page  => 0
                      );
end;
/
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
                        ,   p_source        => 'declare
                                                    v_audit_data clob := :body;
                                                begin
                                                    -- store incoming message for logging purposes
                                                    icca_incoming_messages.p_store_incoming_message(
                                                        p_api_method   => ''POST'',
                                                        p_api_endpoint => ''api/postaudits/'',
                                                        p_msg          => v_audit_data
                                                    );

                                                end;
                                                '
                        );

    commit;                          
end;
/

                                                    -- process the actual audit data
                                                    icca_audit_post_api.p_process_audit(v_audit_data); 