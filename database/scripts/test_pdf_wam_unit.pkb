create or replace package body test_pdf_wam_unit as

    procedure test_valid_template_routing is
        l_is_valid boolean;
    begin
        -- Test valid templates defined in icca_pdf_generator.f_is_valid_template
        ut.expect(icca_pdf_generator.f_is_valid_template('ICCA_RAPPORT')).to_be_true;
        ut.expect(icca_pdf_generator.f_is_valid_template('ICCA_ZONDER_CIJFERS')).to_be_true;
        ut.expect(icca_pdf_generator.f_is_valid_template('FASE_CONTROL')).to_be_true;
        ut.expect(icca_pdf_generator.f_is_valid_template('BURO_HENNIE_DEKKER')).to_be_true;
    end test_valid_template_routing;

    procedure test_invalid_template_routing is
    begin
        -- Test invalid template
        ut.expect(icca_pdf_generator.f_is_valid_template('ONBEKEND_TEMPLATE')).to_be_false;
        ut.expect(icca_pdf_generator.f_is_valid_template('icca_rapport')).to_be_false; -- case sensitive
    end test_invalid_template_routing;

    procedure test_icca_rapport_json_gen is
        l_json clob;
        l_dummy_adt_id number;
    begin
        -- Get a valid audit ID or create one for testing
        select max(id) into l_dummy_adt_id from icca_audits where audit_completed = 'Y';
        
        if l_dummy_adt_id is not null then
            l_json := icca_pdf_icca_data.f_get_main_json(l_dummy_adt_id);
            
            -- Expect CLOB to be returned
            ut.expect(l_json).not_to_be_null;
            
            -- Check for mandatory keys using JSON_EXISTS
            -- (Basic validation string search for unit test)
            ut.expect(dbms_lob.instr(l_json, 'pdf_filename')).to_be_greater_than(0);
            ut.expect(dbms_lob.instr(l_json, 'ICCA_RAPPORT')).to_be_greater_than(0);
        else
            ut.fail('Geen test data gevonden in icca_audits');
        end if;
    end test_icca_rapport_json_gen;

    procedure test_fase_control_json_gen is
        l_json clob;
        l_dummy_adt_id number;
    begin
        select max(id) into l_dummy_adt_id from icca_audits where audit_completed = 'Y';
        
        if l_dummy_adt_id is not null then
            l_json := icca_pdf_fase_control_data.f_get_main_json(l_dummy_adt_id);
            
            ut.expect(l_json).not_to_be_null;
            ut.expect(dbms_lob.instr(l_json, 'FASE_CONTROL')).to_be_greater_than(0);
            -- Specific for Fase Control:
            ut.expect(dbms_lob.instr(l_json, 'Kwaliteitsmeting')).to_be_greater_than(0);
        else
            ut.fail('Geen test data gevonden in icca_audits');
        end if;
    end test_fase_control_json_gen;

    procedure test_bhd_pareto_logic is
        l_json clob;
        l_dummy_adt_id number;
    begin
        select max(id) into l_dummy_adt_id from icca_audits where audit_completed = 'Y';
        
        if l_dummy_adt_id is not null then
            -- Verify it runs without exceptions
            l_json := icca_pdf_buro_hennie_dekker_data.f_get_main_json(l_dummy_adt_id);
            ut.expect(l_json).not_to_be_null;
            ut.expect(dbms_lob.instr(l_json, 'BURO_HENNIE_DEKKER')).to_be_greater_than(0);
            ut.expect(dbms_lob.instr(l_json, 'pareto_data')).to_be_greater_than(0);
        else
            ut.fail('Geen test data gevonden in icca_audits');
        end if;
    end test_bhd_pareto_logic;

end test_pdf_wam_unit;
/
