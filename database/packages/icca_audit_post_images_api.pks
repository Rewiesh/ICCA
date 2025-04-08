create or replace package icca_audit_post_images_api
is
    -- image record
    type t_image is record
        (   name        varchar2(100)
        ,   mime_type   varchar2(100)
        ,   image_data  blob
        );

    procedure p_msg_handler(    p_incomming_message_id in number 
                            ,   po_result              in varchar2
                            );

end icca_audit_post_images_api;
/
