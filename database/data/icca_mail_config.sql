-- SMTP configuratie
merge into icca_mail_config t
using (
    select 'SMTP_HOST' as config_key, 
           'smtp.transip.email' as config_value, 
           'SMTP server hostname' as description,
           'N' as is_encrypted
    from dual
) s
on (t.config_key = s.config_key)
when matched then
    update set 
        t.config_value = s.config_value,
        t.description = s.description
when not matched then
    insert (config_key, config_value, description, is_encrypted)
    values (s.config_key, s.config_value, s.description, s.is_encrypted);

merge into icca_mail_config t
using (
    select 'SMTP_PORT' as config_key,
           '465' as config_value,
           'SMTP server port (465=SSL, 587=TLS)' as description,
           'N' as is_encrypted
    from dual
) s
on (t.config_key = s.config_key)
when matched then
    update set 
        t.config_value = s.config_value,
        t.description = s.description
when not matched then
    insert (config_key, config_value, description, is_encrypted)
    values (s.config_key, s.config_value, s.description, s.is_encrypted);

merge into icca_mail_config t
using (
    select 'SMTP_USERNAME' as config_key,
           'info@iccaadvies.eu' as config_value,
           'SMTP authentication username' as description,
           'N' as is_encrypted
    from dual
) s
on (t.config_key = s.config_key)
when matched then
    update set 
        t.config_value = s.config_value,
        t.description = s.description
when not matched then
    insert (config_key, config_value, description, is_encrypted)
    values (s.config_key, s.config_value, s.description, s.is_encrypted);

merge into icca_mail_config t
using (
    select 'SMTP_PASSWORD' as config_key,
           'zyrpeb-nipraF-9fyppo' as config_value,
           'SMTP authentication password' as description,
           'N' as is_encrypted
    from dual
) s
on (t.config_key = s.config_key)
when matched then
    update set 
        t.config_value = s.config_value,
        t.description = s.description
when not matched then
    insert (config_key, config_value, description, is_encrypted)
    values (s.config_key, s.config_value, s.description, s.is_encrypted);

merge into icca_mail_config t
using (
    select 'SMTP_FROM_ADDRESS' as config_key,
           'info@iccaadvies.eu' as config_value,
           'Default from address' as description,
           'N' as is_encrypted
    from dual
) s
on (t.config_key = s.config_key)
when matched then
    update set 
        t.config_value = s.config_value,
        t.description = s.description
when not matched then
    insert (config_key, config_value, description, is_encrypted)
    values (s.config_key, s.config_value, s.description, s.is_encrypted);

merge into icca_mail_config t
using (
    select 'SMTP_FROM_NAME' as config_key,
           'ICCA Advies' as config_value,
           'Default from name' as description,
           'N' as is_encrypted
    from dual
) s
on (t.config_key = s.config_key)
when matched then
    update set 
        t.config_value = s.config_value,
        t.description = s.description
when not matched then
    insert (config_key, config_value, description, is_encrypted)
    values (s.config_key, s.config_value, s.description, s.is_encrypted);

commit;