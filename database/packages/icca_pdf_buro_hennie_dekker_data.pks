create or replace package icca_pdf_buro_hennie_dekker_data
as
    --
    -- Genereer de volledige JSON voor het Buro Hennie Dekker rapport
    --
    function f_get_main_json (
        p_adt_id in number
    ) return clob;

end icca_pdf_buro_hennie_dekker_data;
/