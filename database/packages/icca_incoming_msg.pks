create or replace package icca_incoming_msg
is
    
    procedure p_store_incoming_message( p_api_method    in varchar2
                                    ,   p_api_endpoint  in varchar2
                                    ,   p_msg           in clob 
                                    );

end icca_incoming_msg;
/