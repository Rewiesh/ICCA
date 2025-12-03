--
-- Test Template PDF - Pagina 1
-- Test de BURO_HENNIE_DEKKER template met dummy data
--

SET SERVEROUTPUT ON
SET VERIFY OFF

DECLARE
    l_pdf       BLOB;
    l_doc_id    NUMBER;
BEGIN
    -- Roep test functie aan
    l_pdf := icca_pdf_generator.f_test_template_page1;
    
    -- Sla PDF op in database
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Opslaan in icca_documents...');
    
    INSERT INTO icca_documents (name, mime_type, image_data)
    VALUES (
        'template_test_page1_' || TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') || '.pdf',
        'application/pdf',
        l_pdf
    )
    RETURNING id INTO l_doc_id;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('✓ PDF opgeslagen als document ID: ' || l_doc_id);
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Download PDF met:');
    DBMS_OUTPUT.PUT_LINE('  SELECT image_data FROM icca_documents WHERE id = ' || l_doc_id || ';');
    DBMS_OUTPUT.PUT_LINE('  Rechter klik op BLOB → Export → Save As → test.pdf');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('FAILED: ' || SQLERRM);
        RAISE;
END;
/
