create or replace package icca_pdf_generator_test as
    --
    -- Test: genereer PDF van raw HTML (legacy endpoint)
    -- Gebruikt legacy endpoint: POST http://localhost:3000/generate-pdf
    -- Nuttig voor testen zonder template systeem
    --
    function f_generate_pdf_from_html (
        p_html in clob
    ) return blob;

    --
    -- Test: genereer PDF met template en dummy data (pagina 1)
    -- Test de volledige template-based flow met simpele test data
    -- Gebruikt: POST http://localhost:3000/generate-pdf-template
    --
    --
    -- Test: genereer PDF met volledige dummy data (Hennie Dekker)
    -- Standalone test met hardcoded JSON uit test-buro-hennie.html
    --
    function f_test_hennie_dekker_dummy return blob;

    function f_test_template_page1 return blob;

    --
    -- Test: genereer PDF met volledige dummy data (ICCA Rapport)
    -- Standalone test met hardcoded JSON uit test-templates.html
    --
    function f_test_icca_rapport_dummy return blob;

    --
    -- Test: genereer PDF met volledige dummy data (Fase Control)
    -- Standalone test met hardcoded JSON
    --
    function f_test_fase_control_dummy return blob;

    --
    -- Test: genereer PDF met volledige dummy data (ICCA Zonder Cijfers)
    -- Standalone test met hardcoded JSON (zonder historisch_verloop)
    --
    function f_test_icca_zonder_cijfers_dummy return blob;

end icca_pdf_generator_test;
/