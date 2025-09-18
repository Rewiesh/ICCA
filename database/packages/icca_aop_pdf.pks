create or replace package icca_aop_pdf
is
--global variables

    function f_get_imgs_html(p_doc_ids varchar2, p_duplicate_number number default null)
    return clob;
end icca_aop_pdf;