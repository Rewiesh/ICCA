create or replace package body icca_json_util
is

    function f_pretty_json( p_json in clob )
    return clob
    is
        l_pretty_json clob;
    begin
        --
        select json_serialize(p_json returning clob pretty)
        into l_pretty_json
        from dual;
        --
        return l_pretty_json;
        --
    end f_pretty_json;

    -- Utility function to sanitize strings for JSON
    function f_sanitize_json_string( p_input varchar2 ) 
    return varchar2 
    is
    begin
        if p_input is null then
            return null;
        end if;

        return regexp_replace(replace(
                            replace(
                                replace(
                                    replace(
                                        replace(
                                            p_input, 
                                            chr(10), '\n'  -- Replace new line
                                        ), 
                                        chr(13), '\r'  -- Replace carriage return
                                    ), 
                                    '"', '\"'  -- Escape double quotes
                                ), 
                                chr(9), ' '  -- Replace tabs with spaces
                            ), 
                            chr(92), '\\'  -- Escape backslashes
                        ), '[[:cntrl:]]', '');  -- Remove all control characters (U+0000 - U+001F)
    end f_sanitize_json_string;

                    
end icca_json_util;
/