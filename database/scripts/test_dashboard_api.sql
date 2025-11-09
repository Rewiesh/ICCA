set serveroutput on;
set linesize 32000;
set longchunksize 32000;

declare
    -- ========================================
    -- TEST CONFIGURATIE
    -- ========================================
    
    -- Test parameters
    v_audit_code    varchar2(100) := null;           -- null = alle audits, of specifieke code bijv '17301'
    v_company_name  varchar2(200) := null;           -- null = alle companies, of specifieke naam bijv 'Stichting Kolom'
    
    -- ========================================
    -- INTERNE VARIABELEN
    -- ========================================
    l_result_json   clob;
    l_length        number;
    l_chunk_size    number := 4000;
    l_offset        number := 1;
    
begin
    --
    dbms_output.put_line('========================================');
    dbms_output.put_line('TEST: icca_dashboard_api_pkg.p_get_data');
    dbms_output.put_line('========================================');
    dbms_output.put_line('');
    
    -- Test parameters weergeven
    dbms_output.put_line('Test Parameters:');
    dbms_output.put_line('  p_audit_code   : ' || nvl(v_audit_code, '[NULL - alle audits]'));
    dbms_output.put_line('  p_company_name : ' || nvl(v_company_name, '[NULL - alle companies]'));
    dbms_output.put_line('');
    
    -- ========================================
    -- TEST 1: Roep functie aan en haal resultaat op
    -- ========================================
    dbms_output.put_line('--- TEST 1: Functie aanroepen ---');
    
    begin
        -- Roep de functie aan via de package
        -- We gebruiken p_get_data procedure die output via htp.p doet
        -- Voor directe test gebruiken we de onderliggende functie
        
        -- Eerst testen we de data ophalen
        declare
            l_dashboard_rec icca_dashboard_api_pkg.t_dashboard_api;
        begin
            l_dashboard_rec := icca_dashboard_api_pkg.f_dashboard_api_rec(
                p_audit_code    => v_audit_code,
                p_company_name  => v_company_name
            );
            
            dbms_output.put_line('✓ Data opgehaald');
            dbms_output.put_line('  Aantal resultaten: ' || l_dashboard_rec.audit_results.count);
            
            if l_dashboard_rec.audit_results.count > 0 then
                dbms_output.put_line('');
                dbms_output.put_line('--- SAMPLE DATA (eerste 3 records) ---');
                
                for i in 1..least(3, l_dashboard_rec.audit_results.count) loop
                    dbms_output.put_line('');
                    dbms_output.put_line('Record ' || i || ':');
                    dbms_output.put_line('  Company Name    : ' || l_dashboard_rec.audit_results(i).company_name);
                    dbms_output.put_line('  Name            : ' || l_dashboard_rec.audit_results(i).name);
                    dbms_output.put_line('  Region          : ' || l_dashboard_rec.audit_results(i).region);
                    dbms_output.put_line('  Date            : ' || l_dashboard_rec.audit_results(i).date);
                    dbms_output.put_line('  Audit Code      : ' || l_dashboard_rec.audit_results(i).audit_code);
                    dbms_output.put_line('  Category Name   : ' || l_dashboard_rec.audit_results(i).category_name);
                    dbms_output.put_line('  Area Code       : ' || l_dashboard_rec.audit_results(i).area_code);
                    dbms_output.put_line('  GK Grens        : ' || l_dashboard_rec.audit_results(i).gk_grens);
                    dbms_output.put_line('  Resultaat       : ' || l_dashboard_rec.audit_results(i).resultaat);
                    dbms_output.put_line('  Element Type    : ' || l_dashboard_rec.audit_results(i).element_type_value);
                    dbms_output.put_line('  Error Type      : ' || l_dashboard_rec.audit_results(i).error_type_value);
                    dbms_output.put_line('  Fout            : ' || l_dashboard_rec.audit_results(i).fout);
                    dbms_output.put_line('  Jaar            : ' || l_dashboard_rec.audit_results(i).jaar);
                    dbms_output.put_line('  Aantal Contr    : ' || l_dashboard_rec.audit_results(i).aantal_contr);
                end loop;
            else
                dbms_output.put_line('⚠ Geen resultaten gevonden met deze filters');
            end if;
            
        exception
            when others then
                dbms_output.put_line('✗ Error bij data ophalen: ' || sqlerrm);
                raise;
        end;
        
    end;
    
    dbms_output.put_line('');
    
    -- ========================================
    -- TEST 2: JSON conversie testen
    -- ========================================
    dbms_output.put_line('--- TEST 2: JSON conversie ---');
    
    begin
        declare
            l_dashboard_rec icca_dashboard_api_pkg.t_dashboard_api;
            l_json_obj      json_object_t;
        begin
            l_dashboard_rec := icca_dashboard_api_pkg.f_dashboard_api_rec(
                p_audit_code    => v_audit_code,
                p_company_name  => v_company_name
            );
            
            l_json_obj := icca_dashboard_api_pkg.f_dashboard_api_json_obj(l_dashboard_rec);
            l_result_json := l_json_obj.to_clob();
            
            l_length := dbms_lob.getlength(l_result_json);
            
            dbms_output.put_line('✓ JSON gegenereerd');
            dbms_output.put_line('  JSON grootte: ' || l_length || ' bytes');
            dbms_output.put_line('');
            dbms_output.put_line('--- JSON OUTPUT (eerste 2000 chars) ---');
            dbms_output.put_line(dbms_lob.substr(l_result_json, 2000, 1));
            
            if l_length > 2000 then
                dbms_output.put_line('');
                dbms_output.put_line('... [JSON output afgekapt, totaal ' || l_length || ' bytes] ...');
            end if;
            
        exception
            when others then
                dbms_output.put_line('✗ Error bij JSON conversie: ' || sqlerrm);
                raise;
        end;
        
    end;
    
    dbms_output.put_line('');
    
    -- ========================================
    -- TEST 3: Chunking test (voor grote datasets)
    -- ========================================
    dbms_output.put_line('--- TEST 3: Chunking simulatie ---');
    
    begin
        if l_result_json is not null then
            l_length := dbms_lob.getlength(l_result_json);
            l_offset := 1;
            l_chunk_size := 32000;
            
            declare
                l_chunk_count number := 0;
            begin
                while l_offset <= l_length loop
                    l_chunk_count := l_chunk_count + 1;
                    l_offset := l_offset + l_chunk_size;
                end loop;
                
                dbms_output.put_line('✓ Chunking simulatie');
                dbms_output.put_line('  Chunk grootte   : ' || l_chunk_size || ' bytes');
                dbms_output.put_line('  Totale grootte  : ' || l_length || ' bytes');
                dbms_output.put_line('  Aantal chunks   : ' || l_chunk_count);
                
            end;
        end if;
        
    exception
        when others then
            dbms_output.put_line('✗ Error bij chunking test: ' || sqlerrm);
    end;
    
    dbms_output.put_line('');
    dbms_output.put_line('========================================');
    dbms_output.put_line('TEST COMPLEET!');
    dbms_output.put_line('========================================');
    
exception
    when others then
        dbms_output.put_line('');
        dbms_output.put_line('========================================');
        dbms_output.put_line('ERROR!');
        dbms_output.put_line('========================================');
        dbms_output.put_line('Error: ' || sqlerrm);
        dbms_output.put_line('========================================');
        raise;
end;
/
