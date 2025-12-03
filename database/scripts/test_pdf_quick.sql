--
-- ========================================================================
-- Quick Test: Genereer PDF en sla op in icca_documents
-- ========================================================================
--

set serveroutput on
set define off

declare
    l_pdf_blob      blob;
    l_adt_id        number := 9024; -- vervang met geldige audit_id
    l_doc_id        number;
begin
    --
    -- Genereer PDF
    --
    dbms_output.put_line('Genereer PDF voor audit ' || l_adt_id || '...');
    
    l_pdf_blob := icca_pdf_generator.f_generate_audit_pdf(
        p_adt_id => l_adt_id
    );
    
    dbms_output.put_line('✓ PDF gegenereerd: ' || dbms_lob.getlength(l_pdf_blob) || ' bytes');
    
    --
    -- Sla PDF op in icca_documents met CORRECTE mime type
    --
    dbms_output.put_line('Sla PDF op in icca_documents...');
    
    insert into icca_documents (
        name
      , mime_type
      , image_data
    )
    values (
        'audit_' || l_adt_id || '_' || to_char(sysdate, 'YYYYMMDD_HH24MISS') || '.pdf'
      , 'application/pdf'  -- CORRECT MIME TYPE!
      , l_pdf_blob
    )
    returning id into l_doc_id;
    
    commit;
    
    dbms_output.put_line('✓ PDF opgeslagen met document ID: ' || l_doc_id);
    dbms_output.put_line('');
    dbms_output.put_line('Download PDF via APEX met:');
    dbms_output.put_line('  select image_data, name, mime_type');
    dbms_output.put_line('  from icca_documents');
    dbms_output.put_line('  where id = ' || l_doc_id);
    
exception
    when others then
        rollback;
        dbms_output.put_line('✗ ERROR: ' || sqlerrm);
        raise;
end;
/
