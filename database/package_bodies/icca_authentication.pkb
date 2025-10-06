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
    -- Genereer veilig wachtwoord
    function f_generate_password(
        pi_numbers      in number default 2
    ,   pi_specialchar  in number default 1
    ,   pi_lowercase    in number default 2
    ,   pi_uppercase    in number default 2
    ) return varchar2
    is
        l_password        varchar2(200);
        l_length          number := 12;
        l_iterations      number := 0;
        l_max_iterations  number := 500;
        l_invalid_chars   constant varchar2(50) := '/`;+,.@$~^_{}\|';
    begin
        --
        loop
            l_password := dbms_random.string('p', l_length);
            l_iterations := l_iterations + 1;
            --
            -- Check password voor verplichte character types en ongeldige karakters
            exit when (regexp_count(l_password, '[a-z]') >= pi_lowercase
                    and regexp_count(l_password, '[A-Z]') >= pi_uppercase
                    and regexp_count(l_password, '[0-9]') >= pi_numbers
                    and regexp_count(l_password, '([ ' || apex_escape.regexp(l_invalid_chars) || ']|\[|\])') = 0
                    )
                    or l_iterations = l_max_iterations;
        end loop;
        --
        if l_iterations = l_max_iterations then
            raise_application_error(-20010, 'Kon geen geldig wachtwoord genereren na ' || l_max_iterations || ' pogingen');
        end if;
        --
        logger.log_info(
            p_text  => 'Wachtwoord gegenereerd',
            p_scope => 'icca_authentication.f_generate_password',
            p_extra => 'LENGTH=' || length(l_password) || ', ITERATIONS=' || l_iterations
        );
        --
        return l_password;
        --
    exception
        when others then
            logger.log_error(
                p_text  => 'Error in f_generate_password',
                p_scope => 'icca_authentication.f_generate_password',
                p_extra => 'ERROR=' || sqlerrm
            );
            raise;
    end f_generate_password;    
    --
    -----------------------------------------------------------------------------------------
    --  
    function f_check_is_user_exists( pi_username in varchar2 )
    return boolean
    is  
        cursor c_user( b_username in varchar2 )
        is
            select 1
            from   icca_users
            where  upper(username) = upper(b_username)
            ;
        
        -- variables
        ln_dummy number;
    begin
        -- check if user exists
        open  c_user( b_username => pi_username );
        fetch c_user into ln_dummy;
        close c_user;   
        
        return true;
    exception
    when no_data_found
    then
        return false;
    when others 
    then
        return false;
    end f_check_is_user_exists;
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
    -- Verstuur wachtwoord reset mail
    procedure p_send_password_reset( pi_username in varchar2 )
    is
        -- cursors
        cursor c_get_user( b_username in varchar2 )
        is
            select  usr.id
            ,       usr.username
            ,       usr.email
            ,       usr.active
            from    icca_users usr
            where   upper(usr.username) = upper(b_username)
            ;
        
        -- variables
        lr_user         c_get_user%rowtype;
        l_new_password  varchar2(25);
        l_mail_log_id   number;
        l_recipients    sys.odcivarchar2list;
    begin
        --
        -- Validatie
        if pi_username is null then
            raise_application_error(-20011, 'Gebruikersnaam is verplicht');
        end if;
        --
        -- Haal gebruiker op
        open    c_get_user( b_username => pi_username );
        fetch   c_get_user into lr_user;
        
        if c_get_user%notfound 
        then
            close c_get_user;
            logger.log_warning(
                p_text  => 'Gebruiker niet gevonden voor password reset',
                p_scope => 'icca_user_auth.p_send_password_reset',
                p_extra => 'USERNAME=' || pi_username
            );
            raise_application_error(-20012, 'Gebruiker niet gevonden of niet actief');
        end if;
        
        close c_get_user;
        --
        -- Check email adres
        if lr_user.email is null then
            raise_application_error(-20013, 'Geen email adres bekend voor gebruiker ' || pi_username);
        end if;
        --
        -- Genereer nieuw wachtwoord
        l_new_password := f_generate_password(
            pi_numbers     => 2
        ,   pi_specialchar => 0  -- Geen special chars voor gebruiksgemak
        ,   pi_lowercase   => 2
        ,   pi_uppercase   => 2
        );
        --
        -- Update wachtwoord in database
        update  icca_users
        set     password    = f_get_hash(l_new_password)
        ,       active      = 'Y'
        where   id = lr_user.id
        ;
        --
        commit;
        --
        -- Verstuur mail
        l_recipients := sys.odcivarchar2list(lr_user.email);
        --
        icca_mail.p_send_template_email(
            p_template_name => 'PASSWORD_RESET'
        ,   p_to            => l_recipients
        ,   p_param01       => lr_user.username
        ,   p_param02       => apex_escape.html(l_new_password)
        ,   po_log_id       => l_mail_log_id
        );
        --
        -- Log success
        logger.log_info(
            p_text  => 'Password reset mail verstuurd',
            p_scope => 'icca_user_auth.p_send_password_reset',
            p_extra => 'USERNAME=' || pi_username || 
                    ', EMAIL=' || lr_user.email ||
                    ', MAIL_LOG_ID=' || l_mail_log_id
        );
        --
    exception
        when others then
            rollback;
            logger.log_error(
                p_text  => 'Error in p_send_password_reset',
                p_scope => 'icca_user_auth.p_send_password_reset',
                p_extra => 'USERNAME=' || pi_username ||
                        ', ERROR=' || sqlerrm ||
                        ', BACKTRACE=' || dbms_utility.format_error_backtrace
            );
            raise;
    end p_send_password_reset;  
    --
end icca_authentication;
/