# ICCA PDF Generator - Testing Gids

## Test Functies

### 1. `f_generate_audit_pdf` - Productie Functie

Genereert PDF voor een audit met template systeem.

```sql
-- Gebruik
DECLARE
    l_pdf BLOB;
BEGIN
    l_pdf := icca_pdf_generator.f_generate_audit_pdf(
        p_adt_id => 9024
    );
    
    DBMS_OUTPUT.PUT_LINE('PDF: ' || DBMS_LOB.GETLENGTH(l_pdf) || ' bytes');
END;
/
```

**Vereisten:**
- Audit moet bestaan in `icca_audits`
- Client moet `audit_report_type` hebben
- Data moet beschikbaar zijn in `icca_aop_report_data_vw`
- Template moet bestaan in Node.js

---

### 2. `f_generate_pdf_from_html` - Test Functie ⚡

Genereert PDF van raw HTML (zonder template systeem).

```sql
-- Gebruik
DECLARE
    l_pdf BLOB;
BEGIN
    l_pdf := icca_pdf_generator.f_generate_pdf_from_html(
        p_html => '<html><body><h1>Test</h1></body></html>'
    );
    
    DBMS_OUTPUT.PUT_LINE('PDF: ' || DBMS_LOB.GETLENGTH(l_pdf) || ' bytes');
END;
/
```

**Voordelen:**
- ✅ Geen database dependencies
- ✅ Geen audit_id nodig
- ✅ Snel testen van Node.js connectie
- ✅ Handmatig HTML opstellen mogelijk

**Gebruikt endpoint:** `POST http://localhost:3000/generate-pdf` (legacy)

---

## Test Scripts

### Quick Test (30 seconden)

```bash
sqlplus user/pass@db @scripts/quick_html_test.sql
```

Genereert simpele test PDF zonder opslaan.

**Verwacht:**
```
Genereer simpele test PDF...
✓ PDF: 12345 bytes

PL/SQL procedure successfully completed.
```

---

### Uitgebreide HTML Test

```bash
sqlplus user/pass@db @scripts/test_html_to_pdf.sql
```

Genereert styled HTML PDF en slaat op in `icca_documents`.

**Verwacht:**
```
Test 1: Simpele HTML
====================
HTML size: 2048 bytes

Genereer PDF...
✓ PDF gegenereerd: 15234 bytes

Sla PDF op...
✓ PDF opgeslagen met document ID: 12345

========================================
Test GESLAAGD
========================================
```

---

### Volledige Audit Test

```bash
sqlplus user/pass@db @scripts/test_pdf_quick.sql
```

Genereert PDF voor echte audit met template systeem.

**Let op:** Vervang `9024` met geldige `audit_id` in script!

---

### AOP View Data Check

```bash
sqlplus user/pass@db @scripts/test_aop_view_data.sql
```

Toont beschikbare data in `icca_aop_report_data_vw`.

Gebruik dit als PDF generatie faalt om te zien welke data beschikbaar is.

---

## Troubleshooting Workflow

### Stap 1: Test Node.js Service

```bash
# Direct via cURL
curl http://localhost:3000/health

# Of via Oracle
SELECT utl_http.request('http://localhost:3000/health') FROM dual;
```

**Verwacht:** `{"status":"ok","service":"ICCA PDF Generator"...}`

---

### Stap 2: Test HTML → PDF (zonder database)

```sql
@scripts/quick_html_test.sql
```

Als dit **werkt**: Node.js service is OK ✓  
Als dit **faalt**: Probleem met Node.js of ACL rechten ✗

---

### Stap 3: Test Template JSON Builder

```sql
DECLARE
    l_json CLOB;
BEGIN
    l_json := icca_pdf_generator.f_build_hennie_dekker_json(
        p_adt_id => 9024
    );
    
    DBMS_OUTPUT.PUT_LINE(SUBSTR(l_json, 1, 500));
END;
/
```

Als dit **werkt**: JSON builder is OK ✓  
Als dit **faalt**: Probleem met AOP view of audit data ✗

---

### Stap 4: Test Template → PDF

```sql
@scripts/test_pdf_quick.sql
```

Als dit **werkt**: Volledige flow is OK ✓  
Als dit **faalt**: Check Node.js logs voor template errors ✗

---

## Veelvoorkomende Problemen

### Probleem 1: "Connection refused"

**Oorzaak:** Node.js service draait niet

**Oplossing:**
```bash
sudo systemctl status pdf-generator
sudo systemctl start pdf-generator
```

---

### Probleem 2: "ORA-29273: HTTP request failed"

**Oorzaak:** ACL rechten ontbreken

**Oplossing:**
```sql
BEGIN
    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
        host       => 'localhost',
        lower_port => 3000,
        upper_port => 3000,
        ace        => xs$ace_type(
            privilege_list => xs$name_list('http'),
            principal_name => 'JOUW_SCHEMA',
            principal_type => xs_acl.ptype_db
        )
    );
END;
/
COMMIT;
```

---

### Probleem 3: "Template BURO_HENNIE_DEKKER not found"

**Oorzaak:** Template bestand bestaat niet of cache is leeg

**Oplossing:**
```bash
# Check bestand
ls -la /home/icca-dashboard/generatepdf/templates/BURO_HENNIE_DEKKER.hbs

# Refresh cache
curl http://localhost:3000/templates/refresh
```

---

### Probleem 4: "PDF is 0 bytes of corrupt"

**Oorzaak:** Verkeerde MIME type bij opslaan

**Oplossing:**
```sql
-- FOUT ❌
INSERT INTO icca_documents (mime_type, ...) 
VALUES ('application/json', ...);

-- CORRECT ✅
INSERT INTO icca_documents (mime_type, ...) 
VALUES ('application/pdf', ...);
```

---

### Probleem 5: "No data found in icca_aop_report_data_vw"

**Oorzaak:** Audit heeft geen data in AOP view

**Oplossing:**
```sql
-- Check audit
@scripts/test_aop_view_data.sql

-- Pas audit_id aan naar audit met data
SELECT adt_id FROM icca_aop_report_data_vw WHERE ROWNUM = 1;
```

---

## Best Practices

### 1. Start Altijd met Quick Test

```sql
@scripts/quick_html_test.sql
```

Dit valideert basis connectiviteit zonder complexe dependencies.

---

### 2. Check Node.js Logs

```bash
# Real-time logs
journalctl -u pdf-generator -f

# Laatste 50 regels
journalctl -u pdf-generator -n 50
```

---

### 3. Gebruik APEX Debug

```sql
-- Enable debug
EXEC apex_debug.enable;

-- Run functie
DECLARE
    l_pdf BLOB;
BEGIN
    l_pdf := icca_pdf_generator.f_generate_audit_pdf(9024);
END;
/

-- Check logs
SELECT * FROM apex_debug_messages
WHERE message_timestamp > SYSDATE - 1/24
ORDER BY message_timestamp DESC;
```

---

### 4. Test Incrementeel

1. ✅ Node.js health check
2. ✅ HTML → PDF (test functie)
3. ✅ JSON builder
4. ✅ Template → PDF (productie functie)

Stop bij eerste fout en los op voordat je verder gaat.

---

## Performance Tips

### Template Cache

Templates worden gecached in Node.js. Na wijzigingen:

```bash
curl http://localhost:3000/templates/refresh
```

Of vanuit Oracle:

```sql
EXEC icca_pdf_generator.p_refresh_template_cache;
```

---

### Browser Reuse

Puppeteer hergebruikt browser instance. Als dit problemen geeft:

```bash
sudo systemctl restart pdf-generator
```

---

## Zie Ook

- `README_FASE1.md` - Volledige documentatie
- `INSTALLATION_CHECKLIST.md` - Installatie stappen
- `test_pdf_generator.sql` - Volledige test suite
