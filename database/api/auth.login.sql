begin
    -- maak een modules aan voor authentication
    ords.define_module(   p_module_name     => 'auth'
                      ,   p_base_path       => 'auth/'
                      ,   p_items_per_page  => 0
                      );
end;
/
begin
    -- maak de tempalte aan coor de module
    ords.define_template(   p_module_name => 'auth'
                        ,   p_pattern     => 'login/'
                        );
end;
/
begin
    -- handler for endpoint
    ords.define_handler(    p_module_name   => 'auth'
                        ,   p_pattern       => 'login/'
                        ,   p_method        => 'POST'
                        ,   p_source_type   => ords.source_type_plsql
                        ,   p_source        => 'begin :result := icca_authentication_ords.is_login_valid(:username, :password); end;' 
                        );
    -- parameter: username
    ords.define_parameter(    p_module_name         => 'auth'
                          ,   p_pattern             => 'login/'
                          ,   p_method              => 'POST'
                          ,   p_name                => 'X-Username'
                          ,   p_bind_variable_name  => 'username'
                          ,   p_source_type         => 'HEADER'
                          ,   p_param_type          => 'STRING'
                          );
    -- parameter: password
    ords.define_parameter(    p_module_name         => 'auth'
                          ,   p_pattern             => 'login/'
                          ,   p_method              => 'POST'
                          ,   p_name                => 'X-Password'
                          ,   p_bind_variable_name  => 'password'
                          ,   p_source_type         => 'HEADER'
                          ,   p_param_type          => 'STRING'
                          ); 

    -- Output response
    ords.define_parameter(    p_module_name         => 'auth'
                          ,   p_pattern             => 'login/'
                          ,   p_method              => 'POST'
                          ,   p_name                => 'result'
                          ,   p_bind_variable_name  => 'result'
                          ,   p_source_type         => 'RESPONSE'
                          ,   p_param_type          => 'STRING'
                          ,   p_access_method       => 'OUT'
                          );    
    commit;                          
end;
/
