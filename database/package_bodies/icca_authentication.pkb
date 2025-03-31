create or replace package body icca_authentication
is
/*
  This package contains functions and procedures relating to managing user authentication
*/
    -- validate user credentials
    function is_login_valid 
      ( p_username  in icca_users.username%type
      , p_password  in icca_users.password%type  
      )
    return boolean
    is
      cursor c_usr(b_username in icca_users.username%type)
        is
          select  *
          from    icca_users usr
          where   upper(usr.username) = upper(b_username)
          and     usr.active = 'Y'
          ;
      
      lr_user         c_usr%rowtype;
      ln_hash_method  pls_integer;
      lb_usr_found    boolean := false;
      lb_login_valid  boolean := false;
    begin
      -- get user credentials
      open  c_usr(b_username => p_username);
      fetch c_usr into lr_user;
      lb_usr_found := c_usr%found;
      close c_usr;

      if lb_usr_found
      then
        lb_login_valid := lr_user.password = p_password;
      end if;

      return lb_login_valid;
    end is_login_valid;

end icca_authentication;
/