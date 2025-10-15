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
    
end icca_file_upload;
/