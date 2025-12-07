create or replace package icca_file_upload as
    
    -- Bestaande functie (behouden voor backwards compatibility)
    function f_save_uploaded_file(
        p_blob          in blob
    ,   p_filename      in varchar2
    ,   p_mime_type     in varchar2 default 'image/png'
    ) return varchar2;
    
    -- NIEUWE functie: upload + insert in één keer
    function f_save_and_register_document(
        p_blob          in blob
    ,   p_filename      in varchar2
    ,   p_mime_type     in varchar2 default 'image/png'
    ,   p_document_name in varchar2 default null  -- Optioneel: anders p_filename
    ) return number;  -- Returnt document ID
    
    -- Functie om BLOB op te halen van document
    function f_get_document_blob(
        p_document_id   in number
    ) return blob;
    
    -- Functie om BLOB te converteren naar Base64 data URL
    function f_blob_to_base64_data_url(
        p_blob          in blob
    ,   p_mime_type     in varchar2 default 'image/jpeg'
    ) return clob;

    function f_get_image_base64(
        p_file_path in varchar2
    ,   p_width     in number default 600
    ,   p_height    in number default 600
    ) return clob;
    
end icca_file_upload;
/