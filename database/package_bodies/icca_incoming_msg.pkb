create or replace package body icca_incoming_msg
is
    
    procedure p_store_incoming_message( p_api_method    in varchar2
                                    ,   p_api_endpoint  in varchar2
                                    ,   p_msg           in clob 
                                    )
    is
    begin
        --
        insert into icca_incoming_messages( api_method, api_endpoint, message )
            values ( p_api_method, p_api_endpoint, p_msg );
        --            
        commit;
        --
    exception
    when others
    then
        -- Log the error
        logger.log_error(   p_text  => 'Error in p_store_incoming_message'
                        ,   p_scope => 'icca_incoming_messages.p_store_incoming_message'
                        ,   p_extra => 'API_METHOD=' || p_api_method || 
                                    ', API_ENDPOINT=' || p_api_endpoint ||
                                    ', ERROR=' || SQLERRM ||
                                    ', BACKTRACE=' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                        );
    end p_store_incoming_message;

end icca_incoming_msg;
/