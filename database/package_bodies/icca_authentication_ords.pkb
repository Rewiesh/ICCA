create or replace package body icca_authentication_ords
is
/*
  This package contains functions and procedures relating to managing user authentication
*/
    -- validate user credentials
    function is_login_valid 
        ( p_username  in icca_users.username%type
        , p_password  in icca_users.password%type  
        )
    return varchar2
    is
        ln_hash_method  pls_integer;
        lb_login_valid  boolean := false;
        l_response      clob;
    begin
        -- get user credentials
        lb_login_valid := icca_authentication.is_login_valid(p_username => p_username, p_password => p_password);
        --
        if lb_login_valid
        then
            --
            l_response := '{"status": "VALID"}';
            --
        else
            --
            l_response := '{"status": "INVALID"}';
            --
        end if;
        --
        return l_response;
        --
    end is_login_valid;
    --
end icca_authentication_ords;
/