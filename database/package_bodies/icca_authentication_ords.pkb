create or replace package body icca_authentication_ords
is
/*
  This package contains functions and procedures relating to managing user authentication
*/
    -----------------------------------------------------------------------------------------
    -- get config value from app configuration
    function f_get_config(
        p_config_key in icca_app_config.config_key%type
    ) return icca_app_config.config_value%type
    is
        cursor c_config(b_config_key in varchar2)
        is
            select config_value
            from   icca_app_config
            where  config_key = b_config_key
            and    active_ind = 'Y';
            
        l_config_value icca_app_config.config_value%type;
    begin
        open  c_config(b_config_key => p_config_key);
        fetch c_config into l_config_value;
        close c_config;
        return l_config_value;
    end f_get_config;

    -----------------------------------------------------------------------------------------
    -- internally fetches the OAuth token using UTL_HTTP and credentials from config table
    function get_oauth_token return varchar2
    is
        l_client_id     varchar2(1000);
        l_client_secret varchar2(1000);
        l_token_url     varchar2(1000);
        l_req           utl_http.req;
        l_resp          utl_http.resp;
        l_text          varchar2(32767);
        l_credentials   varchar2(2000);
        l_post_data     varchar2(1000) := 'grant_type=client_credentials';
        l_access_token  varchar2(4000);
        lc_scope        constant varchar2(100) := 'icca_authentication_ords.get_oauth_token';
    begin
        logger.log('Start ophalen OAuth token', lc_scope);

        -- Fetch settings using the f_get_config helper
        l_client_id     := f_get_config('OAUTH_CLIENT_ID');
        l_client_secret := f_get_config('OAUTH_CLIENT_SECRET');
        l_token_url     := f_get_config('OAUTH_TOKEN_URL');

        logger.log('Token URL: ' || l_token_url, lc_scope);
        logger.log('Client ID: ' || substr(l_client_id, 1, 10) || '...', lc_scope);
        logger.log('Client secret aanwezig: ' || case when l_client_secret is not null then 'JA' else 'NEE' end, lc_scope);

        if l_client_id is null or l_client_secret is null or l_token_url is null then
            logger.log_warning('OAuth config ontbreekt', lc_scope);
            return null;
        end if;

        -- Base64 encode client_id:client_secret for Basic Auth
        l_credentials := utl_raw.cast_to_varchar2(
            utl_encode.base64_encode(
                utl_raw.cast_to_raw(l_client_id || ':' || l_client_secret)
            )
        );
        l_credentials := replace(l_credentials, chr(13)||chr(10), ''); -- remove newlines

        -- Make HTTP Request
        logger.log('OAuth token request naar ' || l_token_url, lc_scope);
        l_req := utl_http.begin_request(l_token_url, 'POST', 'HTTP/1.1');
        utl_http.set_header(l_req, 'Content-Type', 'application/x-www-form-urlencoded');
        utl_http.set_header(l_req, 'Authorization', 'Basic ' || l_credentials);
        utl_http.set_header(l_req, 'Content-Length', length(l_post_data));

        utl_http.write_text(l_req, l_post_data);
        l_resp := utl_http.get_response(l_req);

        utl_http.read_text(l_resp, l_text, 32767);
        logger.log('HTTP status: ' || l_resp.status_code, lc_scope);
        logger.log('OAuth response: ' || substr(l_text, 1, 2000), lc_scope);
        utl_http.end_response(l_resp);

        -- Parse access_token from JSON response using APEX_JSON
        apex_json.parse(l_text);
        l_access_token := apex_json.get_varchar2('access_token');

        logger.log('Access token opgehaald: ' || case when l_access_token is not null then 'JA' else 'NEE' end, lc_scope);
        return l_access_token;
    exception
        when others then
            logger.log_error('Fout bij ophalen OAuth token: ' || sqlerrm || ' - ' || dbms_utility.format_error_backtrace, lc_scope);
            return null;
    end get_oauth_token;

    -----------------------------------------------------------------------------------------
    -- validate user credentials
    function is_login_valid 
        ( p_username  in icca_users.username%type
        , p_password  in icca_users.password%type  
        )
    return varchar2
    is
        lb_login_valid  boolean := false;
        l_access_token  varchar2(4000);
        l_response      clob;
        lc_scope        constant varchar2(100) := 'icca_authentication_ords.is_login_valid';
    begin
        logger.log('Login validatie voor gebruiker: ' || p_username, lc_scope);

        -- get user credentials
        lb_login_valid := icca_authentication.is_login_valid(   p_username      => p_username
                                                            ,   p_password      => p_password
                                                            ,   p_user_group    => 'UGP_PERFORMERS'
                                                            );

        logger.log('Login valid resultaat: ' || case when lb_login_valid then 'VALID' else 'INVALID' end, lc_scope);

        if lb_login_valid
        then
            -- Get the token internally
            l_access_token := get_oauth_token;

            -- status is altijd VALID als de user geauthenticeerd is (backward compatible met oude mob app)
            -- accessToken wordt meegestuurd als bonus voor nieuwe mob app versies
            if l_access_token is not null then
                l_response := '{"status": "VALID", "accessToken": "' || l_access_token || '"}';
                logger.log('Login response met accessToken', lc_scope);
            else
                l_response := '{"status": "VALID"}';
                logger.log_warning('Login response zonder accessToken', lc_scope);
            end if;
        else
            l_response := '{"status": "INVALID"}';
        end if;

        logger.log('Login response: ' || l_response, lc_scope);
        return l_response;
    exception
        when others then
            logger.log_error('Fout bij login validatie: ' || sqlerrm || ' - ' || dbms_utility.format_error_backtrace, lc_scope);
            return '{"status": "ERROR", "message": "' || replace(sqlerrm, '"', '''') || '"}';
    end is_login_valid;
    -----------------------------------------------------------------------------------------
    -- fallback: geeft OAuth client_id + client_secret terug na validatie van de gebruiker
    function get_oauth_credentials
        ( p_username  in icca_users.username%type
        , p_password  in icca_users.password%type
        )
    return varchar2
    is
        lb_login_valid  boolean := false;
        l_client_id     icca_app_config.config_value%type;
        l_client_secret icca_app_config.config_value%type;
        l_response      varchar2(4000);
    begin
        --
        lb_login_valid := icca_authentication.is_login_valid(   p_username      => p_username
                                                            ,   p_password      => p_password
                                                            ,   p_user_group    => 'UGP_PERFORMERS'
                                                            );
        --
        if lb_login_valid
        then
            --
            l_client_id     := f_get_config('OAUTH_CLIENT_ID');
            l_client_secret := f_get_config('OAUTH_CLIENT_SECRET');
            --
            if l_client_id is not null and l_client_secret is not null
            then
                l_response := '{"client_id": "' || l_client_id || '", "client_secret": "' || l_client_secret || '"}';
            else
                l_response := '{"error": "OAuth credentials niet geconfigureerd in icca_app_config"}';
            end if;
            --
        else
            --
            l_response := '{"error": "Ongeldige gebruikersnaam of wachtwoord"}';
            --
        end if;
        --
        return l_response;
        --
    exception
        when others then
            return '{"error": "' || replace(sqlerrm, '"', '''') || '"}';
    end get_oauth_credentials;
    --
end icca_authentication_ords;
/