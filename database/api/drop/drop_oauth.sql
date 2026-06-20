/*
------------------------------------------------------------------------------
Naam      : drop_oauth.sql
Doel      : Verwijder de OAuth client, privilege, role en privilege mapping.
Gebruik   : Draai per blok 1-voor-1 om alles stapsgewijs op te ruimen.
------------------------------------------------------------------------------
*/

------------------------------------------------------------------------------
-- 1. Verwijder de OAuth client
------------------------------------------------------------------------------
begin
    oauth.delete_client(
        p_name => 'audit_mobile_app'
    );
    commit;
exception
    when others then
        -- client bestaat niet of is al verwijderd
        rollback;
end;
/

------------------------------------------------------------------------------
-- 2. Verwijder de privilege mapping op /api/*
------------------------------------------------------------------------------
begin
    ords.delete_privilege_mapping(
        p_privilege_name => 'api_user_priv',
        p_pattern          => '/api/*'
    );
    commit;
exception
    when others then
        rollback;
end;
/

------------------------------------------------------------------------------
-- 3. Verwijder de privilege
------------------------------------------------------------------------------
begin
    ords.delete_privilege(
        p_name => 'api_user_priv'
    );
    commit;
exception
    when others then
        rollback;
end;
/

------------------------------------------------------------------------------
-- 4. Verwijder de role
------------------------------------------------------------------------------
begin
    ords.delete_role(
        p_role_name => 'api_user_role'
    );
    commit;
exception
    when others then
        rollback;
end;
/
