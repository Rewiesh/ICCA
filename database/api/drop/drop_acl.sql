/*
------------------------------------------------------------------------------
Naam      : drop_acl.sql
Doel      : Verwijder de network ACE voor host icca-dashboard.maxapex.net.
------------------------------------------------------------------------------
*/

begin
    dbms_network_acl_admin.remove_host_ace(
        host => 'icca-dashboard.maxapex.net',
        ace  => xs$ace_type(
                    privilege_list => xs$name_list(
                        'connect',
                        'resolve'
                    ),
                    principal_name => 'ICCA'
                )
    );
    commit;
exception
    when others then
        rollback;
end;
/
