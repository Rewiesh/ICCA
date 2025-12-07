create or replace package icca_pdf_icca_zonder_cijfers_data
as
    --
    -- ========================================================================
    -- Package: icca_pdf_icca_zonder_cijfers_data
    -- Doel: Genereer JSON data voor ICCA_ZONDER_CIJFERS template
    --       Verschil met ICCA_RAPPORT: geen historisch_verloop, geen cijfer kolom
    -- Versie: 1.0.0
    -- Datum: 30-11-2025
    -- ========================================================================
    --

    --
    -- Genereer de volledige JSON voor het ICCA Zonder Cijfers rapport
    --
    function f_get_main_json (
        p_adt_id in number
    ) return clob;

end icca_pdf_icca_zonder_cijfers_data;
/
