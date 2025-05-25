create or replace package icca_authentication
is
/*
  This package contains functions and procedures relating to managing user authentication
*/
    --
    -- Get the hash of a password
    function f_get_hash( pi_password in varchar2 )
    return varchar2;
    --
    -- Check if the password is valid
    function f_is_password_valid(   pi_new_password     in varchar2 
                                ,   pi_confirm_password in varchar2
                                )
    return varchar2;
    --
    -- Check if user login is valid
    function is_login_valid 
        ( p_username    in icca_users.username%type
        , p_password    in icca_users.password%type  
        , p_user_group  in icca_user_groups.system_name%type  default null
        )
    return boolean;
    --
end icca_authentication;
/