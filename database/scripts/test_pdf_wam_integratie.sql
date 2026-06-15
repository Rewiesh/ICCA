-- ========================================================================
-- Integratietest voor WAM Printfunctionaliteiten (PDF)
-- ========================================================================
-- Dit script test de End-to-End flow van de PDF generatie via ORDS/PLSQL 
-- naar de Node.js service (http://localhost:3000)
-- Zorg ervoor dat de Node.js server runt voordat u dit script uitvoert!

set serveroutput on size unlimited;

declare
    l_pdf_blob blob;
    l_adt_id   number;
    l_size     number;
    l_magic    varchar2(10);
begin
    dbms_output.put_line('=== START INTEGRATIETEST: PDF GENERATIE ===');
    
    -- 1. Haal een geldige afgeronde audit op
    begin
        select max(id) into l_adt_id 
        from icca_audits 
        where audit_completed = 'Y';
    exception
        when no_data_found then
            dbms_output.put_line('Geen afgeronde audits gevonden om te testen.');
            return;
    end;
    
    dbms_output.put_line('Geselecteerde Audit ID: ' || l_adt_id);
    dbms_output.put_line('Contact maken met Node.js service via icca_pdf_generator...');

    -- 2. Call the generator (this implicitly calls the right data package based on client config)
    begin
        l_pdf_blob := icca_pdf_generator.f_generate_audit_pdf(l_adt_id);
    exception
        when others then
            dbms_output.put_line('FAIL: Er is een exceptie opgetreden tijdens generatie: ' || sqlerrm);
            return;
    end;

    -- 3. Verifieer het resultaat
    if l_pdf_blob is null then
        dbms_output.put_line('FAIL: BLOB is null.');
        return;
    end if;

    l_size := dbms_lob.getlength(l_pdf_blob);
    dbms_output.put_line('Gegenereerde PDF Size: ' || l_size || ' bytes');

    if l_size < 100 then
        dbms_output.put_line('FAIL: BLOB is te klein. Waarschijnlijk een foutmelding/HTML in plaats van een PDF.');
        return;
    end if;

    -- 4. Check Magic Number (%PDF)
    begin
        l_magic := utl_raw.cast_to_varchar2(dbms_lob.substr(l_pdf_blob, 4, 1));
        dbms_output.put_line('File Header (Magic Number): ' || l_magic);
        
        if l_magic = '%PDF' then
            dbms_output.put_line('PASS: Integratietest succesvol! Valide PDF header gevonden.');
        else
            dbms_output.put_line('FAIL: Het geretourneerde bestand is geen valide PDF document.');
        end if;
    exception
        when others then
            dbms_output.put_line('Kon de header niet verifiëren: ' || sqlerrm);
    end;
    
    dbms_output.put_line('=== EINDE INTEGRATIETEST ===');
end;
/
