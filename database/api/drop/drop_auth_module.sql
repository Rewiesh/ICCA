/*
------------------------------------------------------------------------------
Naam      : drop_auth_module.sql
Doel      : Verwijder de ORDS module 'auth' inclusief templates, handlers en
            parameters.
------------------------------------------------------------------------------
*/

begin
    ords.delete_module(
        p_module_name => 'auth'
    );
    commit;
exception
    when others then
        rollback;
end;
/
