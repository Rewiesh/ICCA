create or replace package icca_incoming_msg
is
    
    function f_get_ige_row( p_ige_id in number)
    return icca_incoming_messages%rowtype;
    
    procedure p_store_incoming_message( p_pfr_id        in number default null
                                    ,   p_api_method    in varchar2
                                    ,   p_api_endpoint  in varchar2
                                    ,   p_msg           in clob
                                    ,   po_ige_id       out number
                                    );

end icca_incoming_msg;
/