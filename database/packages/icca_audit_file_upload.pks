create or replace package icca_audit_file_upload
is

    /*******************************************************************************************************************
    *
    *   Package voor het verwerken van Audit JSON Export files die vanuit de Mobiele App zijn geupload via APEX.
    *   Verwerking gebeurt asynchroon via icca_audit_upload_queue en DBMS_SCHEDULER.
    *
    *   Functionality:
    *   1. Submit Upload: Clears file into queue table and starts bg job.
    *   2. Process Job: Parses JSON, extracts user, checks duplicates, saves data via audit_post_api.
    *
    *******************************************************************************************************************/

    -- Submit een upload voor verwerking
    -- p_file_blob: De inhoud van de file
    -- p_filename:  Naam van de file
    -- po_queue_id: Returns de ID van de queue item voor tracking
    procedure p_submit_upload( 
        p_file_blob in blob
    ,   p_filename  in varchar2
    ,   p_cnt_id    in number
    ,   po_queue_id out number
    );

    -- Interne procedure aangeroepen door DBMS_SCHEDULER
    procedure p_process_queue_item( 
        p_queue_id in number 
    );

end icca_audit_file_upload;
/
