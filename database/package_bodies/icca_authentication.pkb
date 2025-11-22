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
    -- Genereer simpel wachtwoord voor performers (mobile app)
    function f_generate_simple_password(
        pi_username in varchar2 default null,
        pi_length   in number   default 8
    ) return varchar2
    is
        l_password      varchar2(200);
        l_base_word     varchar2(50);
        l_number_part   varchar2(10);
        l_word_list     sys.odcivarchar2list;
    begin
        --
        -- Lijst van makkelijk te typen woorden (Nederlands/Engels mix)
        l_word_list := sys.odcivarchar2list(
            'Appel', 'Banaan', 'Citroen', 'Druif', 'Kers',
            'Mango', 'Peer', 'Sinaas', 'Meloen', 'Ananas',
            'Brood', 'Kaas', 'Melk', 'Boter', 'Suiker',
            'Koffie', 'Water', 'Sappen', 'Koeken', 'Chips'
        );
        --
        if pi_username is not null 
        then
            -- Optie A: Gebruik username als basis
            -- Maak eerste letter hoofdletter, rest lowercase
            l_base_word := initcap(lower(pi_username));
            --
            -- Beperk lengte tot 8 karakters voor niet te lang wachtwoord
            if length(l_base_word) > 8 then
                l_base_word := substr(l_base_word, 1, 8);
            end if;
            --
        else
            -- Optie B: Gebruik random woord uit lijst
            l_base_word := l_word_list(dbms_random.value(1, l_word_list.count));
        end if;
        --
        -- Genereer 4-cijferig nummer
        l_number_part := lpad(trunc(dbms_random.value(1000, 9999)), 4, '0');
        --
        -- Combineer
        l_password := l_base_word || l_number_part;
        --
        logger.log_info(
            p_text  => 'Simpel wachtwoord gegenereerd voor performer',
            p_scope => 'icca_authentication.f_generate_simple_password',
            p_extra => 'LENGTH=' || length(l_password) ||
                    ', PATTERN=Word+Numbers' ||
                    ', USERNAME_BASED=' || case when pi_username is not null then 'Y' else 'N' end
        );
        --
        return l_password;
        --
    exception
        when others then
            logger.log_error(
                p_text  => 'Error in f_generate_simple_password',
                p_scope => 'icca_authentication.f_generate_simple_password',
                p_extra => 'ERROR=' || sqlerrm
            );
            raise;
    end f_generate_simple_password;     
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
    -- Wijzig gebruiker wachtwoord
    procedure p_change_password(
        pi_username             in varchar2 default apex_application.g_user
    ,   pi_new_password         in varchar2
    ,   pi_set_force_change     in varchar2 default 'N'
    )
    is
        -- cursors
        cursor c_get_user( b_username in varchar2 )
        is
            select  usr.id
            ,       usr.username
            ,       usr.password
            ,       usr.active
            ,       usr.force_password_change
            ,       ugp.system_name as user_group_system_name
            ,       ugp.name as user_group_name
            from    icca_users          usr
            join    icca_user_groups    ugp on usr.ugp_id = ugp.id
            where   upper(usr.username) = upper(b_username)
            ;
        
        -- variables
        lr_user         c_get_user%rowtype;
        l_validation    varchar2(4000);
        l_old_force     varchar2(1);
    begin
        --
        -- Validatie input parameters
        if pi_username is null then
            raise_application_error(-20001, 'Gebruikersnaam is verplicht');
        end if;
        
        if pi_new_password is null then
            raise_application_error(-20003, 'Nieuw wachtwoord is verplicht');
        end if;
        
        if pi_set_force_change not in ('Y', 'N') then
            raise_application_error(-20005, 'pi_set_force_change moet Y of N zijn');
        end if;
        --
        -- Haal gebruiker op
        open    c_get_user( b_username => pi_username );
        fetch   c_get_user into lr_user;
        
        if c_get_user%notfound 
        then
            close c_get_user;
            logger.log_warning(
                p_text  => 'Gebruiker niet gevonden bij wachtwoord wijziging',
                p_scope => 'icca_authentication.p_change_password',
                p_extra => 'USERNAME=' || pi_username
            );
            raise_application_error(-20006, 'Gebruiker niet gevonden of niet actief');
        end if;
        
        close c_get_user;
        --
        --
        -- Bewaar oude force_password_change waarde voor logging
        l_old_force := lr_user.force_password_change;
        --
        -- Update wachtwoord en force_password_change flag
        update  icca_users
        set     password                = f_get_hash(pi_new_password)
        ,       force_password_change   = pi_set_force_change
        where   id = lr_user.id
        ;
        --
        -- Log success
        logger.log_info(
            p_text  => 'Wachtwoord succesvol gewijzigd',
            p_scope => 'icca_authentication.p_change_password',
            p_extra => 'USERNAME=' || pi_username ||
                    ', USER_GROUP=' || lr_user.user_group_system_name ||
                    ', FORCE_CHANGE_OLD=' || l_old_force ||
                    ', FORCE_CHANGE_NEW=' || pi_set_force_change ||
                    ', CHANGED_BY=' || nvl(v('APP_USER'), user)
        );
        --
    exception
        when others then
            rollback;
            logger.log_error(
                p_text  => 'Error in p_change_password',
                p_scope => 'icca_authentication.p_change_password',
                p_extra => 'USERNAME=' || pi_username ||
                        ', ERROR=' || sqlerrm ||
                        ', BACKTRACE=' || dbms_utility.format_error_backtrace
            );
            raise;
    end p_change_password;
    --
    -----------------------------------------------------------------------------------------
    -- Verstuur nieuwe gebruiker credentials mail
    procedure p_send_new_user_credentials( 
        pi_user_id   in number
    ,   pi_password  in varchar2 default null
    )
    is
        -- cursors
        cursor c_get_user( b_user_id in number )
        is
            select  usr.id
            ,       usr.username
            ,       usr.active
            ,       ugp.system_name as user_group_system_name
            ,       ugp.name as user_group_name
            from    icca_users          usr
            join    icca_user_groups    ugp on usr.ugp_id = ugp.id
            where   usr.id = b_user_id
            ;
        
        cursor c_get_user_emails( b_user_id in number )
        is
            select  email
            from    icca_usr_emails
            where   usr_id = b_user_id
            order by created_date desc  -- meest recente email eerst
            ;
        
        -- variables
        lr_user                 c_get_user%rowtype;
        l_email                 icca_usr_emails.email%type;
        l_password              varchar2(25);
        l_mail_log_id           number;
        l_recipients            sys.odcivarchar2list;
        l_validation            varchar2(4000);
        l_template_name         icca_mail_templates.system_name%type;
        l_force_password_change varchar2(1);
    begin
        --
        -- Validatie
        if pi_user_id is null then
            raise_application_error(-20014, 'User ID is verplicht');
        end if;
        --
        -- Haal gebruiker op inclusief user group
        open    c_get_user( b_user_id => pi_user_id );
        fetch   c_get_user into lr_user;
        
        if c_get_user%notfound 
        then
            close c_get_user;
            logger.log_warning(
                p_text  => 'Gebruiker niet gevonden voor credentials mail',
                p_scope => 'icca_authentication.p_send_new_user_credentials',
                p_extra => 'USER_ID=' || pi_user_id
            );
            raise_application_error(-20015, 'Gebruiker niet gevonden');
        end if;
        
        close c_get_user;
        --
        -- Bepaal template en force password change op basis van user group
        case upper(lr_user.user_group_system_name)
            when 'UGP_PERFORMERS' then
                l_template_name := 'NEW_USER_ACCOUNT_PERFORMER';
                l_force_password_change := 'N';  -- Performers hoeven niet te resetten
            when 'UGP_ADMIN' then
                l_template_name := 'NEW_USER_ACCOUNT';
                l_force_password_change := 'Y';  -- Beheerders moeten resetten
            when 'UGP_CLIENTS' then
                l_template_name := 'NEW_USER_ACCOUNT';
                l_force_password_change := 'Y';  -- Klanten moeten resetten
            else
                -- Default voor onbekende user groups
                l_template_name := 'NEW_USER_ACCOUNT';
                l_force_password_change := 'Y';
        end case;
        --
        logger.log_info(
            p_text  => 'Template en force password change bepaald',
            p_scope => 'icca_authentication.p_send_new_user_credentials',
            p_extra => 'USER_ID=' || pi_user_id ||
                    ', USER_GROUP=' || lr_user.user_group_system_name ||
                    ', TEMPLATE=' || l_template_name ||
                    ', FORCE_PWD_CHANGE=' || l_force_password_change
        );
        --
        -- Haal email adres op
        open    c_get_user_emails( b_user_id => pi_user_id );
        fetch   c_get_user_emails into l_email;
        
        if c_get_user_emails%notfound 
        then
            close c_get_user_emails;
            raise_application_error(-20016, 'Geen email adres bekend voor gebruiker');
        end if;
        
        close c_get_user_emails;
        --
        -- Bepaal wachtwoord: gebruik meegegeven of genereer nieuwe
        if pi_password is null 
        then
            -- Genereer automatisch wachtwoord op basis van user group
            if upper(lr_user.user_group_system_name) = 'UGP_PERFORMERS' 
            then
                -- Simpel wachtwoord voor performers (mobile app)
                l_password := f_generate_simple_password(
                    pi_username => lr_user.username
                );
                
                logger.log_info(
                    p_text  => 'Simpel performer wachtwoord gegenereerd',
                    p_scope => 'icca_authentication.p_send_new_user_credentials',
                    p_extra => 'USER_ID=' || pi_user_id
                );
            else
                -- Complex wachtwoord voor web app users
                l_password := f_generate_password(
                    pi_numbers     => 2
                ,   pi_specialchar => 0
                ,   pi_lowercase   => 2
                ,   pi_uppercase   => 2
                );
                
                logger.log_info(
                    p_text  => 'Complex wachtwoord gegenereerd',
                    p_scope => 'icca_authentication.p_send_new_user_credentials',
                    p_extra => 'USER_ID=' || pi_user_id
                );
            end if;
        else
            -- Valideer meegegeven wachtwoord
            l_validation := f_is_password_valid(
                pi_new_password     => pi_password,
                pi_confirm_password => pi_password
            );
            
            if l_validation is not null 
            then
                raise_application_error(-20017, 'Wachtwoord voldoet niet aan eisen: ' || l_validation);
            end if;
            
            l_password := pi_password;
            
            logger.log_info(
                p_text  => 'Meegegeven wachtwoord gebruikt',
                p_scope => 'icca_authentication.p_send_new_user_credentials',
                p_extra => 'USER_ID=' || pi_user_id
            );
        end if;
        --
        -- Update wachtwoord in database met juiste force_password_change waarde
        update  icca_users
        set     password                = f_get_hash(l_password)
        ,       active                  = 'Y'
        ,       force_password_change   = l_force_password_change
        where   id = lr_user.id
        ;
        --
        commit;
        --
        -- Verstuur mail met juiste template
        l_recipients := sys.odcivarchar2list(l_email);
        --
        icca_mail.p_send_template_email(
            p_template_name => l_template_name
        ,   p_to            => l_recipients
        ,   p_param01       => lr_user.username
        ,   p_param02       => apex_escape.html(l_password)
        ,   po_log_id       => l_mail_log_id
        );
        --
        -- Log success
        logger.log_info(
            p_text  => 'Nieuwe gebruiker credentials mail verstuurd',
            p_scope => 'icca_authentication.p_send_new_user_credentials',
            p_extra => 'USER_ID=' || pi_user_id || 
                    ', USERNAME=' || lr_user.username ||
                    ', USER_GROUP=' || lr_user.user_group_system_name ||
                    ', EMAIL=' || l_email ||
                    ', PASSWORD_SOURCE=' || case when pi_password is null then 'GENERATED' else 'PROVIDED' end ||
                    ', TEMPLATE=' || l_template_name ||
                    ', FORCE_PASSWORD_CHANGE=' || l_force_password_change ||
                    ', MAIL_LOG_ID=' || l_mail_log_id
        );
        
    exception
        when others then
            rollback;
            logger.log_error(
                p_text  => 'Error in p_send_new_user_credentials',
                p_scope => 'icca_authentication.p_send_new_user_credentials',
                p_extra => 'USER_ID=' || pi_user_id ||
                        ', ERROR=' || sqlerrm ||
                        ', BACKTRACE=' || dbms_utility.format_error_backtrace
            );
            raise;
    end p_send_new_user_credentials;
    --
    -----------------------------------------------------------------------------------------
    -- Verstuur wachtwoord reset mail
    procedure p_send_password_reset( 
        pi_username         in varchar2
    ,   pi_email_addresses  in varchar2 default null
    ,   pi_new_password     in varchar2 default null
    )
    is
        -- cursors
        cursor c_get_user( b_username in varchar2 )
        is
            select  usr.id
            ,       usr.username
            ,       usr.active
            ,       ugp.system_name as user_group_system_name
            ,       ugp.name as user_group_name
            from    icca_users          usr
            join    icca_user_groups    ugp on usr.ugp_id = ugp.id
            where   upper(usr.username) = upper(b_username)
            ;
        
        cursor c_get_user_emails( b_user_id in number )
        is
            select  email
            from    icca_usr_emails
            where   usr_id = b_user_id
            order by created_date desc  -- meest recente email eerst
            ;
        
        -- variables
        lr_user                 c_get_user%rowtype;
        l_new_password          varchar2(25);
        l_mail_log_id           number;
        l_recipients            sys.odcivarchar2list := sys.odcivarchar2list();
        l_template_name         icca_mail_templates.system_name%type;
        l_force_password_change varchar2(1);
        l_email_count           number := 0;
        l_email_list            varchar2(4000);
        l_validation            varchar2(4000);
    begin
        --
        -- Validatie
        if pi_username is null then
            raise_application_error(-20011, 'Gebruikersnaam is verplicht');
        end if;
        --
        -- Haal gebruiker op inclusief user group
        open    c_get_user( b_username => pi_username );
        fetch   c_get_user into lr_user;
        
        if c_get_user%notfound 
        then
            close c_get_user;
            logger.log_warning(
                p_text  => 'Gebruiker niet gevonden voor password reset',
                p_scope => 'icca_authentication.p_send_password_reset',
                p_extra => 'USERNAME=' || pi_username
            );
            raise_application_error(-20012, 'Gebruiker niet gevonden of niet actief');
        end if;
        
        close c_get_user;
        --
        -- Bepaal email adressen: custom of uit database
        if pi_email_addresses is not null 
        then
            -- Gebruik meegegeven comma-separated emails
            logger.log_info(
                p_text  => 'Gebruik custom email adressen',
                p_scope => 'icca_authentication.p_send_password_reset',
                p_extra => 'USERNAME=' || pi_username ||
                        ', EMAILS=' || pi_email_addresses
            );
            --
            -- Split comma-separated string en voeg toe aan recipients list
            for rec in (
                select trim(regexp_substr(pi_email_addresses, '[^,]+', 1, level)) as email
                from   dual
                connect by level <= regexp_count(pi_email_addresses, ',') + 1
            ) loop
                if rec.email is not null then
                    l_recipients.extend;
                    l_recipients(l_recipients.count) := rec.email;
                    l_email_list := l_email_list || rec.email || '; ';
                    l_email_count := l_email_count + 1;
                end if;
            end loop;
            --
            if l_email_count = 0 then
                raise_application_error(-20018, 'Geen geldige email adressen gevonden in parameter');
            end if;
            --
        else
            -- Haal ALLE email adressen op uit icca_usr_emails
            logger.log_info(
                p_text  => 'Haal email adressen op uit icca_usr_emails',
                p_scope => 'icca_authentication.p_send_password_reset',
                p_extra => 'USERNAME=' || pi_username ||
                        ', USER_ID=' || lr_user.id
            );
            --
            for email_rec in c_get_user_emails( b_user_id => lr_user.id ) 
            loop
                l_recipients.extend;
                l_recipients(l_recipients.count) := email_rec.email;
                l_email_list := l_email_list || email_rec.email || '; ';
                l_email_count := l_email_count + 1;
            end loop;
            --
            if l_email_count = 0 then
                raise_application_error(-20013, 'Geen email adres bekend voor gebruiker ' || pi_username);
            end if;
            --
        end if;
        --
        -- Trim trailing semicolon
        l_email_list := rtrim(l_email_list, '; ');
        --
        logger.log_info(
            p_text  => 'Email adressen verzameld',
            p_scope => 'icca_authentication.p_send_password_reset',
            p_extra => 'USERNAME=' || pi_username ||
                    ', EMAIL_COUNT=' || l_email_count ||
                    ', EMAILS=' || l_email_list
        );
        --
        -- Bepaal template en force password change op basis van user group
        case upper(lr_user.user_group_system_name)
            when 'UGP_PERFORMERS' then
                l_template_name := 'PASSWORD_RESET_PERFORMER';
                l_force_password_change := 'N';  -- Performers hoeven niet te resetten
            when 'UGP_ADMIN' then
                l_template_name := 'PASSWORD_RESET';
                l_force_password_change := 'Y';  -- Beheerders moeten resetten
            when 'UGP_CLIENTS' then
                l_template_name := 'PASSWORD_RESET';
                l_force_password_change := 'Y';  -- Klanten moeten resetten
            else
                -- Default voor onbekende user groups
                l_template_name := 'PASSWORD_RESET';
                l_force_password_change := 'Y';
        end case;
        --
        logger.log_info(
            p_text  => 'Password reset - template en force password change bepaald',
            p_scope => 'icca_authentication.p_send_password_reset',
            p_extra => 'USERNAME=' || pi_username ||
                    ', USER_GROUP=' || lr_user.user_group_system_name ||
                    ', TEMPLATE=' || l_template_name ||
                    ', FORCE_PWD_CHANGE=' || l_force_password_change
        );
        --
        -- Bepaal wachtwoord: gebruik meegegeven of genereer nieuwe
        if pi_new_password is not null 
        then
            -- Gebruik meegegeven wachtwoord            
            l_new_password := pi_new_password;
            
            logger.log_info(
                p_text  => 'Meegegeven wachtwoord gebruikt',
                p_scope => 'icca_authentication.p_send_password_reset',
                p_extra => 'USERNAME=' || pi_username ||
                        ', USER_GROUP=' || lr_user.user_group_system_name
            );
        else
            -- Genereer automatisch wachtwoord op basis van user group
            if upper(lr_user.user_group_system_name) = 'UGP_PERFORMERS' 
            then
                -- Simpel wachtwoord voor performers (mobile app)
                l_new_password := f_generate_simple_password(
                    pi_username => lr_user.username
                );
                
                logger.log_info(
                    p_text  => 'Simpel performer wachtwoord gegenereerd',
                    p_scope => 'icca_authentication.p_send_password_reset',
                    p_extra => 'USERNAME=' || pi_username
                );
            else
                -- Complex wachtwoord voor web app users
                l_new_password := f_generate_password(
                    pi_numbers     => 2
                ,   pi_specialchar => 0
                ,   pi_lowercase   => 2
                ,   pi_uppercase   => 2
                );
                
                logger.log_info(
                    p_text  => 'Complex wachtwoord gegenereerd',
                    p_scope => 'icca_authentication.p_send_password_reset',
                    p_extra => 'USERNAME=' || pi_username
                );
            end if;
        end if;
        --
        -- Update wachtwoord in database met juiste force_password_change waarde
        update  icca_users
        set     password                = f_get_hash(l_new_password)
        ,       active                  = 'Y'
        ,       force_password_change   = l_force_password_change
        where   id = lr_user.id
        ;
        --
        commit;
        --
        -- Verstuur mail met juiste template naar alle recipients
        icca_mail.p_send_template_email(
            p_template_name => l_template_name
        ,   p_to            => l_recipients
        ,   p_param01       => lr_user.username
        ,   p_param02       => apex_escape.html(l_new_password)
        ,   po_log_id       => l_mail_log_id
        );
        --
        -- Log success
        logger.log_info(
            p_text  => 'Password reset mail verstuurd',
            p_scope => 'icca_authentication.p_send_password_reset',
            p_extra => 'USERNAME=' || pi_username || 
                    ', USER_GROUP=' || lr_user.user_group_system_name ||
                    ', EMAIL_COUNT=' || l_email_count ||
                    ', EMAILS=' || l_email_list ||
                    ', EMAIL_SOURCE=' || case when pi_email_addresses is not null then 'CUSTOM' else 'DATABASE' end ||
                    ', PASSWORD_SOURCE=' || case when pi_new_password is not null then 'PROVIDED' else 'GENERATED' end ||
                    ', TEMPLATE=' || l_template_name ||
                    ', FORCE_PASSWORD_CHANGE=' || l_force_password_change ||
                    ', MAIL_LOG_ID=' || l_mail_log_id
        );
        --
    exception
        when others then
            rollback;
            logger.log_error(
                p_text  => 'Error in p_send_password_reset',
                p_scope => 'icca_authentication.p_send_password_reset',
                p_extra => 'USERNAME=' || pi_username ||
                        ', EMAIL_ADDRESSES_PARAM=' || pi_email_addresses ||
                        ', NEW_PASSWORD_PARAM=' || case when pi_new_password is not null then 'PROVIDED' else 'NULL' end ||
                        ', ERROR=' || sqlerrm ||
                        ', BACKTRACE=' || dbms_utility.format_error_backtrace
            );
            raise;
    end p_send_password_reset;
    --
    -----------------------------------------------------------------------------------------
    -- Sentry function voor APEX session validatie
    -- Controleert of gebruiker force_password_change heeft en redirect indien nodig
    function f_is_session_valid( 
        pi_username       in varchar2 default apex_application.g_user
    ,   pb_is_public_user in boolean  default apex_authentication.is_public_user
    ,   pi_app_page       in number   default apex_application.g_flow_step_id
    ) return boolean
    is
        -- cursor get user
        cursor c_get_user( b_username in varchar2 )
        is
            select  usr.id
            ,       usr.username
            ,       usr.force_password_change
            ,       usr.active
            ,       ugp.system_name as user_group_system_name
            from    icca_users          usr
            join    icca_user_groups    ugp on usr.ugp_id = ugp.id
            where   upper(usr.username) = upper(b_username)
            and     usr.active = 'Y'
            ;
        
        -- variables
        lr_usr               c_get_user%rowtype;
        lv_redirect          varchar2(200);
        l_is_public_user     constant boolean        := apex_authentication.is_public_user;
        l_app_user           constant varchar2(4000) := apex_application.g_user;
        l_app_page           constant number         := apex_application.g_flow_step_id;
    begin
        --
        -- Check voor public users (niet ingelogd)
        if l_is_public_user 
        then
            -- Sta alleen public pages toe
            if l_app_page not in (100, 110)
            then
                logger.log_warning(
                    p_text  => 'Sentry: Public user probeert protected page te bereiken',
                    p_scope => 'icca_authentication.f_is_session_valid',
                    p_extra => 'PAGE=' || l_app_page
                );
                
                -- Redirect naar login page
                lv_redirect := apex_page.get_url( p_page => 100 );
                apex_util.redirect_url( 
                    p_url              => lv_redirect,
                    p_reset_htp_buffer => true
                );
            end if;
            
            return true;
        end if;
        
        --
        -- Check voor ingelogde gebruikers
        -- Haal gebruiker op
        open    c_get_user( b_username => upper(l_app_user) );
        fetch   c_get_user into lr_usr;
        
        if c_get_user%notfound 
        then
            close c_get_user;
            
            logger.log_warning(
                p_text  => 'Sentry: Gebruiker niet gevonden of niet actief',
                p_scope => 'icca_authentication.f_is_session_valid',
                p_extra => 'USERNAME=' || l_app_user ||
                        ', PAGE=' || l_app_page
            );
            
            -- Gebruiker is niet geldig, redirect naar login
            lv_redirect := apex_page.get_url( p_page => 100 );
            apex_util.redirect_url( 
                p_url              => lv_redirect,
                p_reset_htp_buffer => true
            );
        end if;
        
        close c_get_user;
        
        --
        -- Check force_password_change
        if lr_usr.force_password_change = 'Y' 
        then
            -- Gebruiker MOET wachtwoord wijzigen
            if l_app_page not in (100, 112)
            then
                -- Redirect naar change password page
                logger.log_info(
                    p_text  => 'Force password change - redirect naar page 112',
                    p_scope => 'icca_authentication.f_is_session_valid',
                    p_extra => 'USERNAME=' || l_app_user ||
                            ', CURRENT_PAGE=' || l_app_page ||
                            ', USER_GROUP=' || lr_usr.user_group_system_name
                );
                
                lv_redirect := apex_page.get_url( p_page => 112 );
                apex_util.redirect_url( 
                    p_url              => lv_redirect,
                    p_reset_htp_buffer => true
                );
            end if;
        else
            -- Gebruiker MOET GEEN WACHTWOORD WIJZIGEN
            if l_app_page in (112)
            then
                -- Redirect naar change password page
                logger.log_info(
                    p_text  => 'Force password change - redirect naar page 1',
                    p_scope => 'icca_authentication.f_is_session_valid',
                    p_extra => 'USERNAME=' || l_app_user ||
                            ', CURRENT_PAGE=' || l_app_page ||
                            ', USER_GROUP=' || lr_usr.user_group_system_name
                );
                
                lv_redirect := apex_page.get_url( p_page => 1 );
                apex_util.redirect_url( 
                    p_url              => lv_redirect,
                    p_reset_htp_buffer => true
                );
            end if;
        end if;
        
        -- Sessie is geldig
        return true;
        --
    exception
        when others then
            logger.log_error(
                p_text  => 'Error in f_is_session_valid',
                p_scope => 'icca_authentication.f_is_session_valid',
                p_extra => 'USERNAME=' || l_app_user ||
                        ', PAGE=' || l_app_page ||
                        ', ERROR=' || sqlerrm ||
                        ', BACKTRACE=' || dbms_utility.format_error_backtrace
            );
            -- Bij error: laat gebruiker door (fail-open voor betere user experience)
            return true;
    end f_is_session_valid;
    --
end icca_authentication;
/