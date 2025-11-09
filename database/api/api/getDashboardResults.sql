begin
    -- maak de template aan voor de module
    ords.define_template(   p_module_name => 'api'
                        ,   p_pattern     => 'getDashboardResults/'
                        );
end;
/
begin
    -- handler for endpoint
    ords.define_handler(    p_module_name   => 'api'
                        ,   p_pattern       => 'getDashboardResults/'
                        ,   p_method        => 'GET'
                        ,   p_source_type   => ords.source_type_plsql
                        ,   p_source        => 'begin
                                                    -- get audit results with filters and pagination
                                                    icca_dashboard_api_pkg.p_get_data(
                                                        p_audit_code   => :audit_code,
                                                        p_company_name => :company_name,
                                                        p_jaar         => :jaar,
                                                        p_maand        => :maand,
                                                        p_page         => nvl(:page, 1),
                                                        p_page_size    => nvl(:page_size, 1000)
                                                    );
                                                end;'
                        );

    -- parameter: audit_code (optioneel via query string)
    ords.define_parameter(    p_module_name         => 'api'
                          ,   p_pattern             => 'getDashboardResults/'
                          ,   p_method              => 'GET'
                          ,   p_name                => 'audit_code'
                          ,   p_bind_variable_name  => 'audit_code'
                          ,   p_source_type         => 'URI'
                          ,   p_param_type          => 'STRING'
                          );

    -- parameter: company_name (optioneel via query string)
    ords.define_parameter(    p_module_name         => 'api'
                          ,   p_pattern             => 'getDashboardResults/'
                          ,   p_method              => 'GET'
                          ,   p_name                => 'company_name'
                          ,   p_bind_variable_name  => 'company_name'
                          ,   p_source_type         => 'URI'
                          ,   p_param_type          => 'STRING'
                          );

    -- parameter: jaar (optioneel via query string)
    ords.define_parameter(    p_module_name         => 'api'
                          ,   p_pattern             => 'getDashboardResults/'
                          ,   p_method              => 'GET'
                          ,   p_name                => 'jaar'
                          ,   p_bind_variable_name  => 'jaar'
                          ,   p_source_type         => 'URI'
                          ,   p_param_type          => 'INT'
                          );

    -- parameter: maand (optioneel via query string)
    ords.define_parameter(    p_module_name         => 'api'
                          ,   p_pattern             => 'getDashboardResults/'
                          ,   p_method              => 'GET'
                          ,   p_name                => 'maand'
                          ,   p_bind_variable_name  => 'maand'
                          ,   p_source_type         => 'URI'
                          ,   p_param_type          => 'INT'
                          );

    -- parameter: page (optioneel via query string)
    ords.define_parameter(    p_module_name         => 'api'
                          ,   p_pattern             => 'getDashboardResults/'
                          ,   p_method              => 'GET'
                          ,   p_name                => 'page'
                          ,   p_bind_variable_name  => 'page'
                          ,   p_source_type         => 'URI'
                          ,   p_param_type          => 'INT'
                          );

    -- parameter: page_size (optioneel via query string)
    ords.define_parameter(    p_module_name         => 'api'
                          ,   p_pattern             => 'getDashboardResults/'
                          ,   p_method              => 'GET'
                          ,   p_name                => 'page_size'
                          ,   p_bind_variable_name  => 'page_size'
                          ,   p_source_type         => 'URI'
                          ,   p_param_type          => 'INT'
                          );

    commit;
end;
/
