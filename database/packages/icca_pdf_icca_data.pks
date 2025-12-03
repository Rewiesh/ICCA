create or replace package icca_pdf_icca_data
as
    --
    -- ========================================================================
    -- Package: icca_pdf_icca_data
    -- Doel: Genereer JSON data voor ICCA_RAPPORT template
    -- Versie: 1.0.0
    -- Datum: 29-11-2025
    -- ========================================================================
    --
    
    --
    -- Genereer de volledige JSON voor het ICCA rapport
    --
   function f_get_main_json (
      p_adt_id in number
   ) return clob;

end icca_pdf_icca_data;
/
