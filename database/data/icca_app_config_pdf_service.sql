-- App configuratie voor PDF service URL
merge into icca_app_config t
using (
    select 'PDF_SERVICE_URL' as config_key, 
        --    'http://localhost:3000' as config_value, 
        'http://icca-dashboard.maxapex.net:3000' as config_value, 
           'URL van de Node.js PDF service' as description,
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
