--
-- ========================================================================
-- Valideer PDF BLOB in database
-- Controleert of BLOB een valide PDF is
-- ========================================================================
--

set serveroutput on
set define off

declare
    l_blob          blob;
    l_doc_id        number;
    l_name          varchar2(200);
    l_mime          varchar2(200);
    l_size          number;
    l_header        raw(20);
    l_footer        raw(20);
    l_header_str    varchar2(20);
    l_footer_str    varchar2(20);
begin
    --
    -- Haal laatste document op
    --
    select  id
    ,       name
    ,       mime_type
    ,       image_data
    ,       dbms_lob.getlength(image_data)
    into    l_doc_id
    ,       l_name
    ,       l_mime
    ,       l_blob
    ,       l_size
    from    (
                select  id
                ,       name
                ,       mime_type
                ,       image_data
                from    icca_documents
                order by id desc
            )
    where   rownum = 1;
    
    dbms_output.put_line('========================================');
    dbms_output.put_line('PDF BLOB Validatie');
    dbms_output.put_line('========================================');
    dbms_output.put_line('Document ID    : ' || l_doc_id);
    dbms_output.put_line('Naam           : ' || l_name);
    dbms_output.put_line('MIME type      : ' || l_mime);
    dbms_output.put_line('Grootte        : ' || l_size || ' bytes');
    dbms_output.put_line('');
    
    --
    -- Check 1: MIME type
    --
    dbms_output.put_line('Check 1: MIME Type');
    dbms_output.put_line('------------------');
    if l_mime = 'application/pdf' then
        dbms_output.put_line('✓ MIME type correct: ' || l_mime);
    else
        dbms_output.put_line('✗ MIME type FOUT: ' || l_mime);
        dbms_output.put_line('  Moet zijn: application/pdf');
    end if;
    dbms_output.put_line('');
    
    --
    -- Check 2: Grootte
    --
    dbms_output.put_line('Check 2: Grootte');
    dbms_output.put_line('------------------');
    if l_size > 1000 then
        dbms_output.put_line('✓ BLOB grootte OK: ' || l_size || ' bytes');
    elsif l_size > 0 then
        dbms_output.put_line('⚠ BLOB is erg klein: ' || l_size || ' bytes');
    else
        dbms_output.put_line('✗ BLOB is leeg!');
    end if;
    dbms_output.put_line('');
    
    --
    -- Check 3: PDF Header (%PDF)
    --
    dbms_output.put_line('Check 3: PDF Header');
    dbms_output.put_line('------------------');
    l_header := dbms_lob.substr(l_blob, 10, 1);
    l_header_str := utl_raw.cast_to_varchar2(l_header);
    
    dbms_output.put_line('Eerste 10 bytes (hex): ' || rawtohex(l_header));
    dbms_output.put_line('Eerste 10 bytes (text): ' || l_header_str);
    
    if l_header_str like '%PDF%' then
        dbms_output.put_line('✓ PDF header gevonden: ' || substr(l_header_str, 1, 8));
    else
        dbms_output.put_line('✗ GEEN PDF header gevonden!');
        dbms_output.put_line('  Verwacht: %PDF-1.x');
        dbms_output.put_line('  Gevonden: ' || l_header_str);
    end if;
    dbms_output.put_line('');
    
    --
    -- Check 4: PDF Footer (%%EOF)
    --
    dbms_output.put_line('Check 4: PDF Footer');
    dbms_output.put_line('------------------');
    l_footer := dbms_lob.substr(l_blob, 10, greatest(1, l_size - 9));
    l_footer_str := utl_raw.cast_to_varchar2(l_footer);
    
    dbms_output.put_line('Laatste 10 bytes (hex): ' || rawtohex(l_footer));
    dbms_output.put_line('Laatste 10 bytes (text): ' || replace(replace(l_footer_str, chr(10), '\n'), chr(13), '\r'));
    
    if l_footer_str like '%EOF%' then
        dbms_output.put_line('✓ PDF footer gevonden');
    else
        dbms_output.put_line('⚠ Geen %%EOF footer gevonden (kan nog steeds valide zijn)');
    end if;
    dbms_output.put_line('');
    
    --
    -- Conclusie
    --
    dbms_output.put_line('========================================');
    dbms_output.put_line('Conclusie:');
    dbms_output.put_line('========================================');
    
    if l_mime = 'application/pdf' and l_size > 1000 and l_header_str like '%PDF%' then
        dbms_output.put_line('✓ BLOB lijkt een valide PDF te zijn');
        dbms_output.put_line('');
        dbms_output.put_line('Als PDF niet opent:');
        dbms_output.put_line('  1. Probleem zit in download mechanisme');
        dbms_output.put_line('  2. Probeer SQL Developer export (zie download_pdf_test.sql)');
        dbms_output.put_line('  3. Check browser console voor errors');
    else
        dbms_output.put_line('✗ BLOB is CORRUPT of GEEN PDF');
        dbms_output.put_line('');
        dbms_output.put_line('Mogelijke oorzaken:');
        dbms_output.put_line('  1. Node.js service genereert geen valide PDF');
        dbms_output.put_line('  2. BLOB wordt verkeerd opgeslagen');
        dbms_output.put_line('  3. Encoding probleem in HTTP transfer');
    end if;
    
exception
    when no_data_found then
        dbms_output.put_line('✗ Geen documenten gevonden in icca_documents');
    when others then
        dbms_output.put_line('✗ ERROR: ' || sqlerrm);
        raise;
end;
/
