create or replace package icca_authentication_ords
is
/*
  This package contains functions and procedures relating to managing user authentication
*/
    function is_login_valid 
        ( p_username  in icca_users.username%type
        , p_password  in icca_users.password%type  
        )
    return varchar2;

end icca_authentication_ords;
/