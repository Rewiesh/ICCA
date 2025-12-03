--
-- ========================================================================
-- Test Script: icca_pdf_generator Package
-- Versie: 1.0.0 - Fase 1
-- ========================================================================
--

set serveroutput on
set define off

declare
    l_pdf_blob      blob;
    l_adt_id        number := 16370; -- vervang met geldige audit_id
    l_pdf_size      number;
begin
    --
    -- Test 1: Genereer PDF voor audit
    --
    dbms_output.put_line('========================================');
    dbms_output.put_line('Test 1: Genereer PDF voor audit ' || l_adt_id);
    dbms_output.put_line('========================================');
    
    begin
        l_pdf_blob := icca_pdf_generator.f_generate_audit_pdf(
            p_adt_id => l_adt_id
        );
        
        l_pdf_size := dbms_lob.getlength(l_pdf_blob);
        
        dbms_output.put_line('✓ PDF gegenereerd: ' || l_pdf_size || ' bytes');
        
        if l_pdf_size > 0 then
            dbms_output.put_line('✓ TEST 1 GESLAAGD');
        else
            dbms_output.put_line('✗ TEST 1 GEFAALD: PDF is leeg');
        end if;
        
    exception
        when others then
            dbms_output.put_line('✗ TEST 1 GEFAALD: ' || sqlerrm);
    end;
    
    dbms_output.put_line('');
    
    --
    -- Test 2: Bouw JSON voor Hennie Dekker template
    --
    dbms_output.put_line('========================================');
    dbms_output.put_line('Test 2: Bouw JSON voor Hennie Dekker');
    dbms_output.put_line('========================================');
    
    declare
        l_json_data clob;
    begin
        l_json_data := icca_pdf_generator.f_build_hennie_dekker_json(
            p_adt_id => l_adt_id
        );
        
        dbms_output.put_line('✓ JSON gebouwd: ' || dbms_lob.getlength(l_json_data) || ' bytes');
        dbms_output.put_line('');
        dbms_output.put_line('JSON preview (eerste 500 chars):');
        dbms_output.put_line(substr(l_json_data, 1, 500));
        dbms_output.put_line('...');
        dbms_output.put_line('✓ TEST 2 GESLAAGD');
        
    exception
        when others then
            dbms_output.put_line('✗ TEST 2 GEFAALD: ' || sqlerrm);
    end;
    
    dbms_output.put_line('');
    
    --
    -- Test 3: Refresh template cache
    --
    dbms_output.put_line('========================================');
    dbms_output.put_line('Test 3: Refresh template cache');
    dbms_output.put_line('========================================');
    
    begin
        icca_pdf_generator.p_refresh_template_cache;
        
        dbms_output.put_line('✓ Template cache refreshed');
        dbms_output.put_line('✓ TEST 3 GESLAAGD');
        
    exception
        when others then
            dbms_output.put_line('✗ TEST 3 GEFAALD: ' || sqlerrm);
    end;
    
    dbms_output.put_line('');
    dbms_output.put_line('========================================');
    dbms_output.put_line('Alle tests afgerond');
    dbms_output.put_line('========================================');
    
end;
/

--
-- Test 4: Check of audit bestaat en client type
--
select  adt.id                      as audit_id
,       adt.code                    as audit_code
,       cnt.company_name            as client
,       cnt.audit_report_type       as template_type
,       adt.audit_completed         as completed
from    icca_audits adt
join    icca_clients cnt on cnt.id = adt.cnt_id
where   adt.id = 16370; -- vervang met geldige audit_id

--
-- Test 5: Check of data beschikbaar is in AOP view
--
select  adt_id
,       audit_report_type
,       substr(aop_data, 1, 200) as aop_data_preview
from    icca_aop_report_data_vw
where   adt_id = 16370; -- vervang met geldige audit_id
