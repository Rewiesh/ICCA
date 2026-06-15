-- App configuratie voor OAuth credentials
merge into icca_app_config t
using (
    select 'OAUTH_CLIENT_ID' as config_key, 
           'AMb-WeETyhV9ZACsY-cufg..' as config_value, 
           'OAuth client_id for mobile application authentication' as description,
           'N' as is_encrypted
    from dual
) s
on (t.config_key = s.config_key)
when matched then
    update set 
        t.config_value = s.config_value,
        t.description = s.description
when not matched then
    insert (config_key, config_value, description, is_encrypted, created_by)
    values (s.config_key, s.config_value, s.description, s.is_encrypted, 'SYSTEM');

merge into icca_app_config t
using (
    select 'OAUTH_CLIENT_SECRET' as config_key, 
           'et3YtHuslDcpW3QIw-TaGw..' as config_value, 
           'OAuth client_secret for mobile application authentication' as description,
           'N' as is_encrypted
    from dual
) s
on (t.config_key = s.config_key)
when matched then
    update set 
        t.config_value = s.config_value,
        t.description = s.description
when not matched then
    insert (config_key, config_value, description, is_encrypted, created_by)
    values (s.config_key, s.config_value, s.description, s.is_encrypted, 'SYSTEM');

merge into icca_app_config t
using (
    select 'OAUTH_TOKEN_URL' as config_key, 
           'https://icca-dashboard-26ai.maxapex.net/ords/icca/oauth/token' as config_value, 
           'OAuth Token endpoint URL for loopback call' as description,
           'N' as is_encrypted
    from dual
) s
on (t.config_key = s.config_key)
when matched then
    update set 
        t.config_value = s.config_value,
        t.description = s.description
when not matched then
    insert (config_key, config_value, description, is_encrypted, created_by)
    values (s.config_key, s.config_value, s.description, s.is_encrypted, 'SYSTEM');

commit;
