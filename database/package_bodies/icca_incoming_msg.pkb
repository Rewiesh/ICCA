create or replace package body icca_incoming_msg
is
    --
    -----------------------------------------------------------------------------------------
    --  get message row
    function f_get_ige_row( p_ige_id in number)
    return icca_incoming_messages%rowtype
    is
        -- cursors
        cursor c_get_ige( b_ige_id in number )
        is
            select  *
            from    icca_incoming_messages
            where   id = b_ige_id
            ;
        --
        -- variables
        lr_ige icca_incoming_messages%rowtype;
    begin
        --
        open    c_get_ige( b_ige_id => p_ige_id );
        fetch   c_get_ige
        into    lr_ige;
        close   c_get_ige;
        --
        return lr_ige;
        --
    end f_get_ige_row;
    --
    -----------------------------------------------------------------------------------------
    --  store incoming message
    procedure p_store_incoming_message( p_pfr_id        in number default null
                                    ,   p_api_method    in varchar2
                                    ,   p_api_endpoint  in varchar2
                                    ,   p_msg           in clob 
                                    ,   po_ige_id       out number
                                    )
    is
    begin
        --
        insert into icca_incoming_messages( pfr_id, api_method, api_endpoint, message )
            values ( p_pfr_id, p_api_method, p_api_endpoint, p_msg )
            returning id into po_ige_id;
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