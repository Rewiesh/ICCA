--
-- Minimale Quick Test
--

SET SERVEROUTPUT ON

DECLARE
    l_pdf BLOB;
BEGIN
    -- Simpelste HTML mogelijk
    l_pdf := icca_pdf_generator.f_generate_pdf_from_html(
        p_html => '<html><body><h1>Test ' || 
                  TO_CHAR(SYSDATE, 'HH24:MI:SS') || 
                  '</h1></body></html>'
    );
    
    -- Toon resultaat
    DBMS_OUTPUT.PUT_LINE('✓ PDF: ' || DBMS_LOB.GETLENGTH(l_pdf) || ' bytes');
    DBMS_OUTPUT.PUT_LINE('✓ Header: ' || 
        UTL_RAW.CAST_TO_VARCHAR2(DBMS_LOB.SUBSTR(l_pdf, 8, 1)));
    
    -- Quick check
    IF UTL_RAW.CAST_TO_VARCHAR2(DBMS_LOB.SUBSTR(l_pdf, 4, 1)) = '%PDF' THEN
        DBMS_OUTPUT.PUT_LINE('✓ VALIDE PDF!');
    ELSE
        DBMS_OUTPUT.PUT_LINE('✗ GEEN PDF!');
        RAISE_APPLICATION_ERROR(-20001, 'Geen valide PDF');
    END IF;
END;
/
