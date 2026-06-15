create or replace package test_pdf_wam_unit as
    -- ========================================================================
    -- utPLSQL Unit Tests voor WAM Printfunctionaliteiten (PDF)
    -- ========================================================================
    
    -- %suite(WAM PDF Generator Unit Tests)
    -- %suitepath(icca.pdf)

    -- %test(Controleer geldige templates whitelist in icca_pdf_generator)
    procedure test_valid_template_routing;

    -- %test(Controleer ongeldige templates whitelist in icca_pdf_generator)
    procedure test_invalid_template_routing;

    -- %test(Verifieer dat ICCA Rapport valid JSON CLOB retourneert)
    procedure test_icca_rapport_json_gen;

    -- %test(Verifieer dat Fase Control valid JSON CLOB retourneert)
    procedure test_fase_control_json_gen;

    -- %test(Verifieer BHD data transformatie logic incl weeknummer en pareto)
    procedure test_bhd_pareto_logic;

end test_pdf_wam_unit;
/
