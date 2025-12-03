create or replace package icca_pdf_fase_control_data
as
    --
    -- ========================================================================
    -- Package: icca_pdf_fase_control_data
    -- Doel: Genereer JSON data voor FASE_CONTROL template
    -- Versie: 1.0.0
    -- Datum: 30-11-2025
    -- ========================================================================
    -- Opmerking: Deze package is identiek aan icca_pdf_icca_data, maar genereert
    --            JSON met template_name = 'FASE_CONTROL' ipv 'ICCA_RAPPORT'
    -- ========================================================================
    --
    
    --
    -- Genereer de volledige JSON voor het FASE_CONTROL rapport
    --
   function f_get_main_json (
      p_adt_id in number
   ) return clob;

end icca_pdf_fase_control_data;
/
