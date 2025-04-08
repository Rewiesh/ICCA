create or replace package body icca_audit_post_images_api
is
    --
    -----------------------------------------------------------------------------------------
    --  convert: AUDIT Json Object 
    function f_image_values( p_image_json_obj in json_object_t )
    return t_audit
    is
        -- variables
        lr_image    t_image;
        l_image_obj json_object_t;
    begin
        --
        l_image_obj := p_audit_json_obj.get_object('audit');
        --
        return lr_audit;
        --
    end f_image_values;
    --
    -----------------------------------------------------------------------------------------
    --  message handler voor ingekomen audit images
    procedure p_msg_handler(    p_incomming_message_id in number 
                            ,   po_result              in varchar2
                            )
    is
        -- variables
        lr_ige              icca_incoming_messages%rowtype;
        l_image             t_image;
        l_image_json_obj    json_object_t;    
    begin
        --
        -- haal de record op die verwerkt moet worden
        lr_ige              := icca_incoming_msg.f_get_ige_row( p_incomming_message_id );    
        --
        -- convert hem van string naar een json object
        l_image_json_obj    := json_object_t.parse( lr_ige.message );
        --
        -- convert het json object naar plsql types
        l_image             := f_image_values( l_image_json_obj );                
    end ;                            
    --
    -----------------------------------------------------------------------------------------
    -- 
end icca_audit_post_images_api;
/
