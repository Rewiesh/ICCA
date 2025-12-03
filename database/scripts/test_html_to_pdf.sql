
set serveroutput on
set define off

declare
    l_html          clob;
    l_pdf_blob      blob;
    l_doc_id        number;
begin
    --
    -- Bouw simpele test HTML
    --
    dbms_output.put_line('Test 1: Simpele HTML');
    dbms_output.put_line('====================');
    
    l_html := '<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Test PDF</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 40px;
        }
        h1 {
            color: #1f4e78;
            border-bottom: 2px solid #1f4e78;
            padding-bottom: 10px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th, td {
            border: 1px solid #ccc;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #1f4e78;
            color: white;
        }
    </style>
</head>
<body>
    <h1>ICCA PDF Generator Test</h1>
    <p><strong>Datum:</strong> ' || to_char(sysdate, 'DD-MM-YYYY HH24:MI:SS') || '</p>
    <p>Dit is een test PDF gegenereerd vanuit Oracle PL/SQL via Node.js Puppeteer service.</p>
    
    <h2>Test Tabel</h2>
    <table>
        <thead>
            <tr>
                <th>Item</th>
                <th>Status</th>
                <th>Opmerking</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>Database connectie</td>
                <td>✓ OK</td>
                <td>Oracle naar Node.js werkt</td>
            </tr>
            <tr>
                <td>HTML rendering</td>
                <td>✓ OK</td>
                <td>Puppeteer converteert HTML</td>
            </tr>
            <tr>
                <td>PDF generatie</td>
                <td>✓ OK</td>
                <td>BLOB wordt correct teruggegeven</td>
            </tr>
        </tbody>
    </table>
    
    <h2>System Info</h2>
    <ul>
        <li>Database: Oracle</li>
        <li>PDF Service: Node.js + Puppeteer</li>
        <li>Endpoint: http://localhost:3000/generate-pdf</li>
        <li>Package: icca_pdf_generator.f_generate_pdf_from_html</li>
    </ul>
</body>
</html>';

    dbms_output.put_line('HTML size: ' || dbms_lob.getlength(l_html) || ' bytes');
    dbms_output.put_line('');
    
    --
    -- Roep test functie aan
    --
    dbms_output.put_line('Genereer PDF...');
    
    l_pdf_blob := icca_pdf_generator.f_generate_pdf_from_html(
        p_html => l_html
    );
    
    dbms_output.put_line('✓ PDF gegenereerd: ' || dbms_lob.getlength(l_pdf_blob) || ' bytes');
    dbms_output.put_line('');
    
    --
    -- Sla PDF op in icca_documents
    --
    dbms_output.put_line('Sla PDF op...');
    
    insert into icca_documents (
        name
      , mime_type
      , image_data
    )
    values (
        'test_html_' || to_char(sysdate, 'YYYYMMDD_HH24MISS') || '.pdf'
      , 'application/pdf'
      , l_pdf_blob
    )
    returning id into l_doc_id;
    
    commit;
    
    dbms_output.put_line('✓ PDF opgeslagen met document ID: ' || l_doc_id);
    dbms_output.put_line('');
    dbms_output.put_line('========================================');
    dbms_output.put_line('Test GESLAAGD');
    dbms_output.put_line('========================================');
    dbms_output.put_line('');
    dbms_output.put_line('Download PDF via APEX met:');
    dbms_output.put_line('  SELECT image_data, name, mime_type');
    dbms_output.put_line('  FROM icca_documents');
    dbms_output.put_line('  WHERE id = ' || l_doc_id);
    
exception
    when others then
        rollback;
        dbms_output.put_line('');
        dbms_output.put_line('✗ ERROR: ' || sqlerrm);
        dbms_output.put_line('');
        raise;
end;
/
