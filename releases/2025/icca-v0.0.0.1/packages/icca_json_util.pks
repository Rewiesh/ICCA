create or replace package icca_json_util
is

    function f_pretty_json( p_json in clob )
    return clob;

    function f_sanitize_json_string(p_input varchar2) 
    return varchar2;

end icca_json_util;
/