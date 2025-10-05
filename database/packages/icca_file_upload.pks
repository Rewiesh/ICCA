create or replace package icca_file_upload as
    
    function f_save_uploaded_file(
        p_blob          in blob
    ,   p_filename      in varchar2
    ,   p_mime_type     in varchar2 default 'image/png'
    ) return varchar2;
    
end icca_file_upload;
/