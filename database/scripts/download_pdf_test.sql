--
-- ========================================================================
-- Download PDF BLOB naar bestand voor testing
-- Dit script schrijft de BLOB direct naar bestand om te testen
-- ========================================================================
--

set serveroutput on
set define off

declare
    l_blob          blob;
    l_buffer        raw(32767);
    l_amount        binary_integer := 32767;
    l_pos           integer := 1;
    l_blob_len      integer;
    l_output        utl_file.file_type;
    l_doc_id        number;
    l_filename      varchar2(200);
begin
    --
    -- Haal laatste PDF document op
    --
    select  id
    ,       name
    ,       image_data
    into    l_doc_id
    ,       l_filename
    ,       l_blob
    from    (
                select  id
                ,       name
                ,       image_data
                from    icca_documents
                where   mime_type = 'application/pdf'
                order by id desc
            )
    where   rownum = 1;
    
    l_blob_len := dbms_lob.getlength(l_blob);
    
    dbms_output.put_line('========================================');
    dbms_output.put_line('PDF Download Test');
    dbms_output.put_line('========================================');
    dbms_output.put_line('Document ID: ' || l_doc_id);
    dbms_output.put_line('Bestandsnaam: ' || l_filename);
    dbms_output.put_line('BLOB lengte: ' || l_blob_len || ' bytes');
    dbms_output.put_line('');
    
    --
    -- Check of BLOB valide lijkt (PDF magic bytes)
    --
    l_buffer := dbms_lob.substr(l_blob, 4, 1);
    
    dbms_output.put_line('Eerste 4 bytes (hex): ' || rawtohex(l_buffer));
    
    if utl_raw.cast_to_varchar2(l_buffer) like '%PDF%' then
        dbms_output.put_line('✓ PDF signature gevonden (valide PDF)');
    else
        dbms_output.put_line('✗ GEEN PDF signature - BLOB is corrupt!');
        dbms_output.put_line('  Verwacht: %PDF');
        dbms_output.put_line('  Gevonden: ' || utl_raw.cast_to_varchar2(l_buffer));
    end if;
    
    dbms_output.put_line('');
    
    --
    -- Schrijf naar bestand (optioneel - alleen als UTL_FILE directory is ingesteld)
    --
    -- l_output := utl_file.fopen('DIR_NAME', l_filename, 'wb', 32767);
    -- 
    -- while l_pos < l_blob_len loop
    --     dbms_lob.read(l_blob, l_amount, l_pos, l_buffer);
    --     utl_file.put_raw(l_output, l_buffer, true);
    --     l_pos := l_pos + l_amount;
    -- end loop;
    -- 
    -- utl_file.fclose(l_output);
    -- dbms_output.put_line('✓ Bestand geschreven');
    
    dbms_output.put_line('========================================');
    dbms_output.put_line('Download via APEX:');
    dbms_output.put_line('========================================');
    dbms_output.put_line('');
    dbms_output.put_line('-- Option 1: Direct download in SQL Developer');
    dbms_output.put_line('SELECT image_data FROM icca_documents WHERE id = ' || l_doc_id || ';');
    dbms_output.put_line('-- Rechter muisknop -> Export -> Save As -> ' || l_filename);
    dbms_output.put_line('');
    dbms_output.put_line('-- Option 2: APEX Download Process');
    dbms_output.put_line('DECLARE');
    dbms_output.put_line('    l_blob BLOB;');
    dbms_output.put_line('BEGIN');
    dbms_output.put_line('    SELECT image_data INTO l_blob FROM icca_documents WHERE id = ' || l_doc_id || ';');
    dbms_output.put_line('    ');
    dbms_output.put_line('    HTP.INIT;');
    dbms_output.put_line('    OWA_UTIL.MIME_HEADER(''application/pdf'', FALSE);');
    dbms_output.put_line('    HTP.P(''Content-Length: '' || DBMS_LOB.GETLENGTH(l_blob));');
    dbms_output.put_line('    HTP.P(''Content-Disposition: attachment; filename="' || l_filename || '"'');');
    dbms_output.put_line('    OWA_UTIL.HTTP_HEADER_CLOSE;');
    dbms_output.put_line('    WPG_DOCLOAD.DOWNLOAD_FILE(l_blob);');
    dbms_output.put_line('END;');
    
exception
    when no_data_found then
        dbms_output.put_line('✗ Geen PDF documenten gevonden in icca_documents');
    when others then
        dbms_output.put_line('✗ ERROR: ' || sqlerrm);
        raise;
end;
/
