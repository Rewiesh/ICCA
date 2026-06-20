/*
------------------------------------------------------------------------------
Naam      : drop_api_module.sql
Doel      : Verwijder de ORDS module 'api' inclusief templates, handlers en
            parameters.
------------------------------------------------------------------------------
*/

begin
    ords.delete_module(
        p_module_name => 'api'
    );
    commit;
exception
    when others then
        rollback;
end;
/
