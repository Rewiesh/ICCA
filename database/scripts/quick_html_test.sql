set serveroutput on

declare
    l_pdf blob;
begin
    dbms_output.put_line('Genereer simpele test PDF...');
    
    l_pdf := icca_pdf_generator.f_generate_pdf_from_html(
        p_html => '<html><body><h1>Test PDF ' || 
                  to_char(sysdate, 'DD-MM-YYYY HH24:MI:SS') || 
                  '</h1><p>Deze PDF werkt!</p></body></html>'
    );
    
    dbms_output.put_line('✓ PDF: ' || dbms_lob.getlength(l_pdf) || ' bytes');
    
    Optioneel: sla op
    INSERT INTO icca_documents (name, mime_type, image_data)
    VALUES ('quick_test.pdf', 'application/pdf', l_pdf);
    COMMIT;
end;
/
