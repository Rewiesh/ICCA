SET SERVEROUTPUT ON;
DECLARE
    l_file UTL_FILE.FILE_TYPE;
BEGIN
    l_file := UTL_FILE.FOPEN('ICCA_UPLOADS', 'testing1.txt', 'W');
    UTL_FILE.PUT_LINE(l_file, 'Test schrijven vanuit Oracle');
    UTL_FILE.FCLOSE(l_file);
    DBMS_OUTPUT.PUT_LINE('Success!');
--EXCEPTION
--    WHEN OTHERS THEN
--        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/
---
DECLARE
    v_blob BLOB;
    v_file_url VARCHAR2(500);
    v_test_data VARCHAR2(1000) := 'Dit is test data voor een upload';
BEGIN
    -- Maak een simpele test blob
    v_blob := UTL_RAW.CAST_TO_RAW(v_test_data);
    
    -- Test de upload functie
    v_file_url := icca_file_upload.save_uploaded_file(
        p_blob      => v_blob,
        p_filename  => 'package-test.txt',
        p_mime_type => 'text/plain'
    );
    
    DBMS_OUTPUT.PUT_LINE('Success!');
    DBMS_OUTPUT.PUT_LINE('File URL: ' || v_file_url);
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/