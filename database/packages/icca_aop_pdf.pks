create or replace package icca_aop_pdf
is
--global variables

    function f_get_imgs_html(p_doc_ids varchar2, p_duplicate_number number default null)
    return clob;

    /*
        For AOP usage to output PDF inline in the browser
    */
    procedure show_inline_pdf (   p_output_blob      in blob
                              ,   p_output_filename  in varchar2
                              ,   p_output_mime_type in varchar2
                              );


end icca_aop_pdf;
/