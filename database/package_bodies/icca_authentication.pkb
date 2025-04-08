create or replace package body icca_authentication
is
/*
  This package contains functions and procedures relating to managing user authentication
*/
    -- validate user credentials
    function is_login_valid(    p_username    in icca_users.username%type
                            ,   p_password    in icca_users.password%type 
                            ,   p_user_group  in icca_user_groups.system_name%type default null
                            )
    return boolean
    is
        -- cursors
        cursor c_usr(   b_username      in icca_users.username%type 
                    ,   b_user_group    in icca_user_groups.system_name%type
                    )
        is
            select  usr.*
            from    icca_users          usr
            join    icca_user_groups    ugp on usr.ugp_id = ugp.id
            where   upper(usr.username) = upper(b_username)
            and     usr.active = 'Y'
            and     ( ( ugp.system_name = b_user_group and b_user_group is not null) 
                    or  b_user_group is null
                    )
            ;
        
        -- variables
        lr_user         c_usr%rowtype;
        ln_hash_method  pls_integer;
        lb_login_valid  boolean := false;
    begin
        -- get user credentials
        open    c_usr(  b_username   => p_username 
                    ,   b_user_group => p_user_group 
                    );
        fetch   c_usr 
        into    lr_user;
        close   c_usr;

        if lr_user.id is not null
        then
            lb_login_valid := lr_user.password = p_password;
        end if;

        return lb_login_valid;
    end is_login_valid;
    --
end icca_authentication;
/