/*
------------------------------------------------------------------------------
Naam      : debug_login_token.sql
Doel      : Debug script voor login + token flow.
            Roept icca_authentication_ords.is_login_valid direct aan en toont
            of de backend een accessToken teruggeeft.
------------------------------------------------------------------------------
*/

set serveroutput on size unlimited;

begin
    dbms_output.put_line('=== DEBUG LOGIN TOKEN ===');
    dbms_output.put_line('');
    dbms_output.put_line('Response login endpoint:');
    dbms_output.put_line(
        icca_authentication_ords.is_login_valid(
            p_username => 'Rewiesh',
            p_password => 'VulJeWachtwoordIn'
        )
    );
end;
/

------------------------------------------------------------------------------
-- Check OAuth configuratie in icca_app_config
------------------------------------------------------------------------------
select config_key
    ,   config_value
from   icca_app_config
where  config_key in ('OAUTH_CLIENT_ID', 'OAUTH_CLIENT_SECRET', 'OAUTH_TOKEN_URL')
order by config_key;

------------------------------------------------------------------------------
-- Check of OAuth client bestaat in ORDS
------------------------------------------------------------------------------
select name
    ,   client_id
    ,   grant_type
from   user_ords_clients
where  name = 'audit_mobile_app';

------------------------------------------------------------------------------
-- Check recente logger entries
------------------------------------------------------------------------------
select id
    ,   logger_level
    ,   scope
    ,   substr(text, 1, 200) as text
    ,   time_stamp
from   logger_logs
where  scope like 'icca_authentication_ords%'
order by time_stamp desc
fetch first 20 rows only;
