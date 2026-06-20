set serveroutput on;
declare
    l_client_id     varchar2(1000);
    l_client_secret varchar2(1000);
    l_token_url     varchar2(1000);
    l_req           utl_http.req;
    l_resp          utl_http.resp;
    l_text          varchar2(32767);
    l_credentials   varchar2(2000);
    l_post_data     varchar2(1000) := 'grant_type=client_credentials';
    l_access_token  varchar2(4000);
    
    -- Helper functie voor config
    function f_get_config(p_config_key in varchar2) return varchar2 is
        l_val varchar2(4000);
    begin
        select config_value into l_val
        from   icca_app_config
        where  config_key = p_config_key
        and    active_ind = 'Y';
        return l_val;
    exception
        when no_data_found then return null;
    end;
begin
    -- 1. Ophalen config (leest nu http uit de tabel!)
    l_client_id     := f_get_config('OAUTH_CLIENT_ID');
    l_client_secret := f_get_config('OAUTH_CLIENT_SECRET');
    l_token_url     := f_get_config('OAUTH_TOKEN_URL');

    dbms_output.put_line('Config URL: ' || l_token_url);
    dbms_output.put_line('Config Client ID: ' || l_client_id);

    -- 2. Base64 encoding credentials
    l_credentials := utl_raw.cast_to_varchar2(
        utl_encode.base64_encode(
            utl_raw.cast_to_raw(l_client_id || ':' || l_client_secret)
        )
    );
    l_credentials := replace(l_credentials, chr(13)||chr(10), ''); 

    -- 3. HTTP Request uitvoeren
    dbms_output.put_line('Starten UTL_HTTP request via HTTPS...');
    
    l_req := utl_http.begin_request(l_token_url, 'POST', 'HTTP/1.1');
    utl_http.set_header(l_req, 'Content-Type', 'application/x-www-form-urlencoded');
    utl_http.set_header(l_req, 'Authorization', 'Basic ' || l_credentials);
    utl_http.set_header(l_req, 'Content-Length', length(l_post_data));
    
    utl_http.write_text(l_req, l_post_data);
    
    l_resp := utl_http.get_response(l_req);
    dbms_output.put_line('HTTP Status Code: ' || l_resp.status_code);
    
    utl_http.read_text(l_resp, l_text, 32767);
    utl_http.end_response(l_resp);

    dbms_output.put_line('Response: ' || l_text);

    -- 4. Parse JSON
    apex_json.parse(l_text);
    l_access_token := apex_json.get_varchar2('access_token');
    dbms_output.put_line('SUCCES! Token opgehaald: ' || substr(l_access_token, 1, 50) || '...');

exception
    when others then
        dbms_output.put_line('Fout opgetreden: ' || sqlerrm);
        dbms_output.put_line(dbms_utility.format_error_backtrace);
end;
/
