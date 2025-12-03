--
-- Simple PDF Generator Test
-- Test de f_generate_pdf_from_html functie
--

SET SERVEROUTPUT ON
SET VERIFY OFF

DECLARE
    l_pdf       BLOB;
    l_html      CLOB;
    l_header    RAW(10);
    l_doc_id    NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('PDF Generator Test');
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Simpele HTML
    l_html := '<html>
<head>
    <title>Oracle Test PDF</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            padding: 40px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
        }
        h1 { 
            color: #667eea; 
            border-bottom: 3px solid #764ba2;
            padding-bottom: 10px;
        }
        .info {
            background: #f0f0f0;
            padding: 15px;
            border-radius: 5px;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Oracle PDF Test ✓</h1>
        <p><strong>Datum:</strong> ' || TO_CHAR(SYSDATE, 'DD-MM-YYYY HH24:MI:SS') || '</p>
        <p><strong>Database:</strong> Oracle APEX</p>
        <p><strong>Service:</strong> Node.js PDF Generator</p>
        
        <div class="info">
            <h3>Status</h3>
            <p>✓ PDF generatie succesvol!</p>
            <p>✓ Node.js service werkt correct</p>
            <p>✓ Oracle integratie OK</p>
        </div>
    </div>
</body>
</html>';

    DBMS_OUTPUT.PUT_LINE('Step 1: HTML voorbereid (' || LENGTH(l_html) || ' bytes)');
    
    -- Genereer PDF
    DBMS_OUTPUT.PUT_LINE('Step 2: Roep PDF service aan...');
    l_pdf := icca_pdf_generator.f_generate_pdf_from_html(p_html => l_html);
    
    DBMS_OUTPUT.PUT_LINE('Step 3: PDF ontvangen: ' || DBMS_LOB.GETLENGTH(l_pdf) || ' bytes');
    
    -- Check PDF header (magic bytes)
    l_header := DBMS_LOB.SUBSTR(l_pdf, 10, 1);
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('PDF Validatie:');
    DBMS_OUTPUT.PUT_LINE('  Header (hex): ' || l_header);
    DBMS_OUTPUT.PUT_LINE('  Header (text): ' || UTL_RAW.CAST_TO_VARCHAR2(DBMS_LOB.SUBSTR(l_pdf, 8, 1)));
    
    -- Check of het een valide PDF is
    IF UTL_RAW.CAST_TO_VARCHAR2(DBMS_LOB.SUBSTR(l_pdf, 4, 1)) = '%PDF' THEN
        DBMS_OUTPUT.PUT_LINE('  Status: ✓ VALIDE PDF!');
        
        -- Sla PDF op in database
        INSERT INTO icca_documents (name, mime_type, image_data)
        VALUES (
            'oracle_test_' || TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') || '.pdf',
            'application/pdf',
            l_pdf
        )
        RETURNING id INTO l_doc_id;
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('✓ PDF opgeslagen in icca_documents');
        DBMS_OUTPUT.PUT_LINE('  Document ID: ' || l_doc_id);
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('Download PDF met:');
        DBMS_OUTPUT.PUT_LINE('  SELECT image_data FROM icca_documents WHERE id = ' || l_doc_id || ';');
        DBMS_OUTPUT.PUT_LINE('  Rechter klik op BLOB → Export → Save As → test.pdf');
        
    ELSE
        DBMS_OUTPUT.PUT_LINE('  Status: ✗ GEEN VALIDE PDF!');
        DBMS_OUTPUT.PUT_LINE('  Eerste 100 chars: ' || 
            UTL_RAW.CAST_TO_VARCHAR2(DBMS_LOB.SUBSTR(l_pdf, 100, 1)));
        RAISE_APPLICATION_ERROR(-20001, 'Geen valide PDF gegenereerd');
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('Test SUCCESVOL!');
    DBMS_OUTPUT.PUT_LINE('========================================');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('========================================');
        DBMS_OUTPUT.PUT_LINE('ERROR!');
        DBMS_OUTPUT.PUT_LINE('========================================');
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('');
        
        -- Check of service draait
        DBMS_OUTPUT.PUT_LINE('Mogelijke oorzaken:');
        DBMS_OUTPUT.PUT_LINE('  1. Node.js service draait niet op http://localhost:3000');
        DBMS_OUTPUT.PUT_LINE('  2. Firewall blokkeert verbinding');
        DBMS_OUTPUT.PUT_LINE('  3. Service geeft error (check console logs)');
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('Start service met:');
        DBMS_OUTPUT.PUT_LINE('  cd "C:\Users\rramcharan\Documents\Q Projecten\Prd\GeneratePdf"');
        DBMS_OUTPUT.PUT_LINE('  node main\server.js');
        
        RAISE;
END;
/
