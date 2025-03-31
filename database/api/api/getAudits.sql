begin
    -- maak een modules aan voor het ophalen van audits
    ords.define_module(   p_module_name     => 'api'
                      ,   p_base_path       => 'api/'
                      ,   p_items_per_page  => 0
                      );
end;
/
begin
    -- maak de tempalte aan voor de module
    ords.define_template(   p_module_name => 'api'
                        ,   p_pattern     => 'getAudits/'
                        );
end;
/
begin
    -- handler for endpoint
    ords.define_handler(    p_module_name   => 'api'
                        ,   p_pattern       => 'getAudits/'
                        ,   p_method        => 'GET'
                        ,   p_source_type   => ords.source_type_plsql
                        ,   p_source        => 'begin icca_audit_get_api.p_get_data(:username); end;'
                        );

    -- parameter: username
    ords.define_parameter(    p_module_name         => 'api'
                          ,   p_pattern             => 'getAudits/'
                          ,   p_method              => 'GET'
                          ,   p_name                => 'X-Username'
                          ,   p_bind_variable_name  => 'username'
                          ,   p_source_type         => 'HEADER'
                          ,   p_param_type          => 'STRING'
                          );

    commit;                          
end;
/
