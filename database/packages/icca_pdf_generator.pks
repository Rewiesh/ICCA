create or replace package icca_pdf_generator as
    --
    -- ========================================================================
    -- Package: icca_pdf_generator
    -- Doel: PDF generatie via Node.js Puppeteer service met Handlebars templates
    -- Versie: 1.0.0 - Fase 1
    -- Auteur: ICCA Team
    -- Datum: 22-11-2025
    -- ========================================================================
    --

    --
    -- Hoofdfunctie: genereer PDF voor een audit
    -- Gebruikt template op basis van icca_clients.audit_report_type
    -- Returnt PDF als BLOB
    --
    function f_generate_audit_pdf (
        p_adt_id in number
    ) return blob;

    --
    -- Helper: roep Node.js PDF service aan met template
    -- Endpoint: POST http://localhost:3000/generate-pdf-template
    -- Valideert template naam tegen whitelist
    --
    function f_call_pdf_service (
        p_template_name in varchar2,
        p_json_data     in clob
    ) return blob;

    --
    -- Utility: refresh template cache in Node.js service
    -- Endpoint: GET http://localhost:3000/templates/refresh
    --
    procedure p_refresh_template_cache;
end icca_pdf_generator;
/