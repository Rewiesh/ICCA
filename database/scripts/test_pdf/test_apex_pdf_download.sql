-- Test APEX PDF Download
-- Test de PDF generatie en download via APEX process
-- Aangepast voor PL/SQL testing met DBMS_OUTPUT

SET SERVEROUTPUT ON
SET VERIFY OFF

DECLARE
    l_pdf       BLOB;
    l_adt_id    NUMBER := 22315;
    l_report_name VARCHAR2(100) := 'report_name';
    l_header    RAW(10);
    l_doc_id    NUMBER;
    l_count     NUMBER;
BEGIN
    -- Valideer audit ID
    SELECT COUNT(*)
    INTO   l_count
    FROM   icca_audits
    WHERE  id = l_adt_id;

    IF l_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Audit ID ' || l_adt_id || ' niet gevonden');
    END IF;

    DBMS_OUTPUT.PUT_LINE('Audit ID: ' || l_adt_id);
    DBMS_OUTPUT.PUT_LINE('Report Name: ' || l_report_name);
    DBMS_OUTPUT.PUT_LINE('');

    -- pdf genereren via jouw functie
    DBMS_OUTPUT.PUT_LINE('Genereren PDF voor audit ' || l_adt_id || '...');

    l_pdf := icca_pdf_generator.f_generate_audit_pdf(p_adt_id => l_adt_id);
    -- l_pdf := icca_pdf_generator.f_test_icca_rapport_dummy;
    -- l_pdf := icca_pdf_generator.f_test_fase_control_dummy;
    -- l_pdf := icca_pdf_generator.f_test_icca_zonder_cijfers_dummy;

    DBMS_OUTPUT.PUT_LINE('✓ PDF gegenereerd: ' || DBMS_LOB.GETLENGTH(l_pdf) || ' bytes');

--    -- Valideer PDF
--    l_header := DBMS_LOB.SUBSTR(l_pdf, 4, 1);
--
--    IF UTL_RAW.CAST_TO_VARCHAR2(l_header) = '%PDF' THEN
--        DBMS_OUTPUT.PUT_LINE('✓ Valide PDF header');
--
--        -- Simuleer APEX download headers
--        DBMS_OUTPUT.PUT_LINE('');
--        DBMS_OUTPUT.PUT_LINE('APEX Download Headers (simulated):');
--        DBMS_OUTPUT.PUT_LINE('  Content-Type: application/pdf');
--        DBMS_OUTPUT.PUT_LINE('  Content-Length: ' || DBMS_LOB.GETLENGTH(l_pdf));
--        DBMS_OUTPUT.PUT_LINE('  Content-Disposition: inline; filename="' || l_report_name || '.pdf"');
--        DBMS_OUTPUT.PUT_LINE('  Cache-Control: max-age=10');
--
--        -- Sla op
--        INSERT INTO icca_documents (name, mime_type, image_data)
--        VALUES (
--            l_report_name || '_' || l_adt_id || '_' || TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') || '.pdf',
--            'application/pdf',
--            l_pdf
--        )
--        RETURNING id INTO l_doc_id;
--
--        COMMIT;
--
--        DBMS_OUTPUT.PUT_LINE('');
--        DBMS_OUTPUT.PUT_LINE('✓ PDF opgeslagen als document ID: ' || l_doc_id);
--        DBMS_OUTPUT.PUT_LINE('');
--        DBMS_OUTPUT.PUT_LINE('Download met:');
--        DBMS_OUTPUT.PUT_LINE('  SELECT image_data FROM icca_documents WHERE id = ' || l_doc_id || ';');
--
--    ELSE
--        DBMS_OUTPUT.PUT_LINE('✗ Geen valide PDF!');
--        RAISE_APPLICATION_ERROR(-20002, 'Geen valide PDF gegenereerd');
--    END IF;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('Test SUCCESVOL!');
    DBMS_OUTPUT.PUT_LINE('========================================');
--
--EXCEPTION
--    WHEN OTHERS THEN
--        DBMS_OUTPUT.PUT_LINE('');
--        DBMS_OUTPUT.PUT_LINE('✗ Fout bij genereren PDF: ' || SQLERRM);
--        DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE);
--        RAISE;
END;
/
