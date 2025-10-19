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
    -- Check if user exists
    function f_check_is_user_exists( pi_username in varchar2 )
    return boolean; 
    --
    -- Check if user login is valid
    function is_login_valid 
        ( p_username    in icca_users.username%type
        , p_password    in icca_users.password%type  
        , p_user_group  in icca_user_groups.system_name%type  default null
        )
    return boolean;
    -- Change user password
    procedure p_change_password(
        pi_username             in varchar2 default apex_application.g_user
    ,   pi_new_password         in varchar2
    ,   pi_set_force_change     in varchar2 default 'N'  -- 'Y' of 'N'
    );    
    --
    -- Send new user credentials email
    procedure p_send_new_user_credentials( 
        pi_user_id   in number
    ,   pi_password  in varchar2 default null  -- optioneel: als null wordt wachtwoord gegenereerd
    );
    --
    -- Send password reset email  
    procedure p_send_password_reset( 
        pi_username         in varchar2,
        pi_email_addresses  in varchar2 default null,
        pi_new_password     in varchar2 default null  -- optioneel: admin kan zelf wachtwoord opgeven
    );
    --
    -- Sentry function for APEX session validation
    function f_is_session_valid( 
        pi_username       in varchar2 default apex_application.g_user
    ,   pb_is_public_user in boolean  default apex_authentication.is_public_user
    ,   pi_app_page       in number   default apex_application.g_flow_step_id
    ) return boolean;    
    --
end icca_authentication;
/