begin
    -- maak de template aan voor de credentials endpoint
    ords.define_template(   p_module_name => 'auth'
                        ,   p_pattern     => 'credentials/'
                        );
end;
/
begin
    -- handler for endpoint
    ords.define_handler(    p_module_name   => 'auth'
                        ,   p_pattern       => 'credentials/'
                        ,   p_method        => 'GET'
                        ,   p_source_type   => ords.source_type_plsql
                        ,   p_source        => 'begin :result := icca_authentication_ords.get_oauth_credentials(:username, :password); end;'
                        );
    -- parameter: username
    ords.define_parameter(    p_module_name         => 'auth'
                          ,   p_pattern             => 'credentials/'
                          ,   p_method              => 'GET'
                          ,   p_name                => 'X-Username'
                          ,   p_bind_variable_name  => 'username'
                          ,   p_source_type         => 'HEADER'
                          ,   p_param_type          => 'STRING'
                          );
    -- parameter: password
    ords.define_parameter(    p_module_name         => 'auth'
                          ,   p_pattern             => 'credentials/'
                          ,   p_method              => 'GET'
                          ,   p_name                => 'X-Password'
                          ,   p_bind_variable_name  => 'password'
                          ,   p_source_type         => 'HEADER'
                          ,   p_param_type          => 'STRING'
                          );
    -- output response
    ords.define_parameter(    p_module_name         => 'auth'
                          ,   p_pattern             => 'credentials/'
                          ,   p_method              => 'GET'
                          ,   p_name                => 'result'
                          ,   p_bind_variable_name  => 'result'
                          ,   p_source_type         => 'RESPONSE'
                          ,   p_param_type          => 'STRING'
                          ,   p_access_method       => 'OUT'
                          );
    commit;
end;
/
