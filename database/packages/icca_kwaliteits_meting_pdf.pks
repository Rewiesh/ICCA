create or replace package icca_kwaliteits_meting_pdf
as
    --
    function f_kwaliteits_rapport_pdf( p_kte_id      in number
                                     )
    return blob;
    --
end icca_kwaliteits_meting_pdf;
/