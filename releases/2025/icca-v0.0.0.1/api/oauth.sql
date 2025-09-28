begin
    ords.create_role('api_user_role');

    ords.create_privilege(
        p_name => 'api_user_priv',
        p_role_name => 'api_user_role',
        p_label => 'icca mob app api user',
        p_description => 'Provide access to audit data');
    commit;
end;
/
begin
    ords.create_privilege_mapping(
        p_privilege_name => 'api_user_priv',
        p_pattern => '/api/*');
    commit;
end;
/
begin
    oauth.create_client(
        p_name => 'audit_mobile_app',
        p_grant_type => 'client_credentials',
        p_privilege_names => 'api_user_priv',
        p_support_email => 'support@example.com');
    commit;
end;
/
begin
    oauth.grant_client_role(
        p_client_name => 'audit_mobile_app',
        p_role_name => 'api_user_role');
    commit;
end;
/
-- select * from user_ords_client_roles where client_name = 'audit_mobile_app';
-- select client_id,client_secret from user_ords_clients where name = 'audit_mobile_app';
-- select privilege_id, name, pattern from user_ords_privilege_mappings;
-- select id,name from user_ords_privileges where name = 'api.audit';
