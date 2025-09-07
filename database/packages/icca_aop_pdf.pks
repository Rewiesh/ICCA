create or replace package icca_aop_pdf
is
--global variables

    function f_get_imgs_html(p_doc_ids varchar2)
    return clob;
end icca_aop_pdf;