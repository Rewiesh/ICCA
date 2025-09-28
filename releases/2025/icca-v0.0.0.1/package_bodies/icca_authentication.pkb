create or replace package body icca_authentication
is
/*
  This package contains functions and procedures relating to managing user authentication
*/
    --
    -----------------------------------------------------------------------------------------
    --  generate hash from password
    --  This function generates a hash from the password using the dbms_crypto package   
    --  grant execute on dbms_crypto to icca
    function f_get_hash( pi_password in varchar2 )
    return varchar2
    is
        -- variables
        lv_raw_password       raw(50);
    begin
        lv_raw_password := dbms_crypto.hash( utl_raw.cast_to_raw(pi_password), dbms_crypto.hash_sh1);
        return utl_raw.cast_to_varchar2( lv_raw_password);
    exception
    when others 
    then
        rollback;
        raise;
    end f_get_hash;
    --
    -----------------------------------------------------------------------------------------
    --  This function checks if the password is valid
    function f_is_password_valid(   pi_new_password     in varchar2 
                                ,   pi_confirm_password in varchar2
                                )
    return varchar2
    is
        -- variables
        li_passwlength  integer        := 12;
        lv_error        varchar2(4000) := null;
    begin
        -- password validations
        if length(trim(pi_new_password)) < li_passwlength
        then
            lv_error := 'Wachtwoord moet minstens ' || li_passwlength ||  ' karakters bevatten.';
        elsif regexp_like(pi_new_password, '[a-z]', 'c') = false
        then
            lv_error := 'Wachtwoord moet minstens 1 kleinletter bevatten.';
        elsif regexp_like(pi_new_password, '[A-Z]', 'c')  = false
        then
            lv_error := 'Wachtwoord moet minstens 1 hoofdletter bevatten.';
        elsif regexp_like(pi_new_password, '[0-9]', 'c') = false
        then
            lv_error := 'Wachtwoord moet minstens 1 cijfer bevatten.';
        elsif regexp_like(pi_new_password, '[@|#|%|*|/|^|$|-|_|=|+|&|^|!|<|>|?]', 'c') = false
        then
            lv_error := 'Wachtwoord moet minstens 1 speciale karakter bevatten.';
        else
            lv_error := null;
        end if;

        return lv_error;
    end f_is_password_valid;                                    
    --
    -----------------------------------------------------------------------------------------
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
            lb_login_valid := lr_user.password = f_get_hash( p_password );
        end if;

        return lb_login_valid;
    end is_login_valid;
    --
    -----------------------------------------------------------------------------------------
    --
end icca_authentication;
/