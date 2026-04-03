--
-- Test script: Audit rapport mail verzending
-- Standalone anonymous block - test alle stappen apart
-- Gebruik: @test_audit_mail.sql
--
set serveroutput on size unlimited
set verify off
set timing on

prompt
prompt ========================================
prompt Test Audit Mail Verzending
prompt ========================================
prompt

accept p_adt_id number prompt 'Voer audit ID in: '
accept p_email char prompt 'Voer email adres in (of comma-separated): '
accept p_use_dummy char prompt 'Dummy PDF gebruiken? (J/N, default N): '

declare
    --
    -- input
    l_adt_id            number := &p_adt_id;
    l_email_input       varchar2(4000) := '&p_email';
    l_use_dummy         varchar2(1) := upper(nvl('&p_use_dummy', 'N'));
    --
    -- audit data
    l_code              varchar2(100);
    l_audit_date        date;
    l_last_control_date date;
    l_company_name      varchar2(255);
    l_cnt_contact       varchar2(255);
    l_location_name     varchar2(255);
    l_cln_contact       varchar2(255);
    --
    -- mail
    l_recipients        sys.odcivarchar2list := sys.odcivarchar2list();
    l_pdf_blob          blob;
    l_pdf_filename      varchar2(255);
    l_contact_person    varchar2(255);
    l_mail_log_id       number;
    --
    -- email parsing
    l_email             varchar2(255);
    l_start             number := 1;
    l_comma_pos         number;
    l_email_regex       constant varchar2(200) := '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';
    --
    -- timing
    l_step_start        timestamp;
    l_total_start       timestamp := systimestamp;
    --
begin
    dbms_output.put_line('');
    dbms_output.put_line('=== START TEST ===');
    dbms_output.put_line('Audit ID : ' || l_adt_id);
    dbms_output.put_line('Email(s) : ' || l_email_input);
    dbms_output.put_line('Tijdstip : ' || to_char(sysdate, 'DD-MM-YYYY HH24:MI:SS'));
    dbms_output.put_line('');

    ---------------------------------------------------------------------------
    -- STAP 1: Parse email adressen (inline, geen package dependency)
    ---------------------------------------------------------------------------
    l_step_start := systimestamp;
    dbms_output.put_line('[STAP 1] Email adressen parsen...');

    if l_email_input is null then
        dbms_output.put_line('  FOUT: Geen email opgegeven!');
        raise_application_error(-20001, 'Geen email opgegeven');
    end if;

    loop
        l_comma_pos := instr(l_email_input, ',', l_start);

        if l_comma_pos = 0 then
            l_email := trim(substr(l_email_input, l_start));
            if l_email is not null then
                if regexp_like(l_email, l_email_regex) then
                    l_recipients.extend;
                    l_recipients(l_recipients.count) := l_email;
                    dbms_output.put_line('  OK: ' || l_email);
                else
                    dbms_output.put_line('  OVERGESLAGEN (ongeldig): ' || l_email);
                end if;
            end if;
            exit;
        else
            l_email := trim(substr(l_email_input, l_start, l_comma_pos - l_start));
            if l_email is not null then
                if regexp_like(l_email, l_email_regex) then
                    l_recipients.extend;
                    l_recipients(l_recipients.count) := l_email;
                    dbms_output.put_line('  OK: ' || l_email);
                else
                    dbms_output.put_line('  OVERGESLAGEN (ongeldig): ' || l_email);
                end if;
            end if;
            l_start := l_comma_pos + 1;
        end if;
    end loop;

    dbms_output.put_line('  Totaal geldige ontvangers: ' || l_recipients.count);
    dbms_output.put_line('  Duur: ' || extract(second from (systimestamp - l_step_start)) || 's');

    if l_recipients.count = 0 then
        dbms_output.put_line('  FOUT: Geen geldige ontvangers!');
        raise_application_error(-20002, 'Geen geldige email adressen');
    end if;

    dbms_output.put_line('');

    ---------------------------------------------------------------------------
    -- STAP 2: Audit gegevens ophalen
    ---------------------------------------------------------------------------
    l_step_start := systimestamp;
    dbms_output.put_line('[STAP 2] Audit gegevens ophalen...');

    begin
        select  adt.code
        ,       adt.audit_date
        ,       adt.last_control_date
        ,       cnt.company_name
        ,       cnt.contact_person
        ,       cln.name
        ,       cln.contact_person
        into    l_code
        ,       l_audit_date
        ,       l_last_control_date
        ,       l_company_name
        ,       l_cnt_contact
        ,       l_location_name
        ,       l_cln_contact
        from    icca_audits             adt
        join    icca_clients            cnt on cnt.id = adt.cnt_id
        join    icca_client_locations   cln on cln.id = adt.cln_id
        where   adt.id = l_adt_id;
    exception
        when no_data_found then
            dbms_output.put_line('  FOUT: Audit ID ' || l_adt_id || ' niet gevonden!');
            raise_application_error(-20003, 'Audit niet gevonden: ' || l_adt_id);
    end;

    l_contact_person := coalesce(l_cnt_contact, 'geachte relatie');

    dbms_output.put_line('  Code           : ' || l_code);
    dbms_output.put_line('  Bedrijf        : ' || l_company_name);
    dbms_output.put_line('  Locatie        : ' || l_location_name);
    dbms_output.put_line('  Contactpersoon : ' || l_contact_person);
    dbms_output.put_line('  Audit datum    : ' || to_char(l_audit_date, 'DD-MM-YYYY'));
    dbms_output.put_line('  Controle datum : ' || to_char(l_last_control_date, 'DD-MM-YYYY'));
    dbms_output.put_line('  Duur: ' || extract(second from (systimestamp - l_step_start)) || 's');
    dbms_output.put_line('');

    ---------------------------------------------------------------------------
    -- STAP 3: PDF genereren (of dummy)
    ---------------------------------------------------------------------------
    l_step_start := systimestamp;
    dbms_output.put_line('[STAP 3] PDF genereren...');

    if l_use_dummy = 'J' then
        --
        -- Dummy PDF: minimale geldige PDF (1 lege pagina)
        --
        dbms_output.put_line('  Modus: DUMMY PDF');
        dbms_lob.createtemporary(l_pdf_blob, true);
        declare
            l_pdf_content varchar2(4000) :=
                '%PDF-1.4' || chr(10) ||
                '1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj' || chr(10) ||
                '2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj' || chr(10) ||
                '3 0 obj<</Type/Page/MediaBox[0 0 612 792]/Parent 2 0 R/Resources<<>>>>endobj' || chr(10) ||
                'xref' || chr(10) ||
                '0 4' || chr(10) ||
                'trailer<</Size 4/Root 1 0 R>>' || chr(10) ||
                'startxref' || chr(10) ||
                '0' || chr(10) ||
                '%%EOF';
        begin
            dbms_lob.writeappend(l_pdf_blob, length(l_pdf_content), utl_raw.cast_to_raw(l_pdf_content));
        end;
        dbms_output.put_line('  Dummy PDF aangemaakt: ' || dbms_lob.getlength(l_pdf_blob) || ' bytes');
    else
        --
        -- Echte PDF via package
        --
        dbms_output.put_line('  Modus: icca_pdf_generator.f_generate_audit_pdf');
        l_pdf_blob := icca_pdf_generator.f_generate_audit_pdf(p_adt_id => l_adt_id);

        if l_pdf_blob is null then
            dbms_output.put_line('  FOUT: PDF blob is NULL!');
            raise_application_error(-20004, 'PDF generatie gaf NULL terug');
        end if;

        dbms_output.put_line('  PDF grootte: ' || dbms_lob.getlength(l_pdf_blob) || ' bytes');

        -- valideer PDF header
        if utl_raw.cast_to_varchar2(dbms_lob.substr(l_pdf_blob, 4, 1)) = '%PDF' then
            dbms_output.put_line('  PDF header: OK');
        else
            dbms_output.put_line('  WAARSCHUWING: Geen geldige PDF header!');
        end if;
    end if;

    dbms_output.put_line('  Duur: ' || extract(second from (systimestamp - l_step_start)) || 's');
    dbms_output.put_line('');

    ---------------------------------------------------------------------------
    -- STAP 4: Bestandsnaam samenstellen
    ---------------------------------------------------------------------------
    dbms_output.put_line('[STAP 4] Bestandsnaam samenstellen...');

    l_pdf_filename := l_code || '.' ||
                      l_company_name || '.' ||
                      l_location_name ||
                      '.pdf';

    dbms_output.put_line('  Filename: ' || l_pdf_filename);
    dbms_output.put_line('');

    ---------------------------------------------------------------------------
    -- STAP 5: Mail versturen via icca_mail.p_send_template_with_pdf
    ---------------------------------------------------------------------------
    l_step_start := systimestamp;
    dbms_output.put_line('[STAP 5] Mail versturen...');
    dbms_output.put_line('  Template: AUDIT_REPORT_GENERATED');
    dbms_output.put_line('  Ontvangers: ' || l_recipients.count);
    for i in 1 .. l_recipients.count loop
        dbms_output.put_line('    -> ' || l_recipients(i));
    end loop;

    icca_mail.p_send_template_with_pdf(
        p_template_name => 'AUDIT_REPORT_GENERATED',
        p_to            => l_recipients,
        p_pdf_blob      => l_pdf_blob,
        p_pdf_filename  => l_pdf_filename,
        p_param01       => l_code,
        p_param02       => l_location_name,
        p_param03       => to_char(l_last_control_date, 'DD-MM-YYYY'),
        p_param04       => l_contact_person,
        po_log_id       => l_mail_log_id
    );

    dbms_output.put_line('  Mail log ID: ' || l_mail_log_id);
    dbms_output.put_line('  Duur: ' || extract(second from (systimestamp - l_step_start)) || 's');
    dbms_output.put_line('');

    ---------------------------------------------------------------------------
    -- STAP 6: Cleanup
    ---------------------------------------------------------------------------
    dbms_output.put_line('[STAP 6] Cleanup...');

    if l_pdf_blob is not null and dbms_lob.istemporary(l_pdf_blob) = 1 then
        dbms_lob.freetemporary(l_pdf_blob);
        dbms_output.put_line('  Tijdelijke PDF blob vrijgegeven');
    end if;

    ---------------------------------------------------------------------------
    -- STAP 7: Verificatie - check mail log
    ---------------------------------------------------------------------------
    dbms_output.put_line('');
    dbms_output.put_line('[STAP 7] Verificatie mail log...');

    if l_mail_log_id is not null then
        declare
            l_status        varchar2(50);
            l_error_msg     varchar2(4000);
            l_to_address    varchar2(4000);
        begin
            select  status, error_message, to_address
            into    l_status, l_error_msg, l_to_address
            from    icca_mail_log
            where   id = l_mail_log_id;

            dbms_output.put_line('  Log ID    : ' || l_mail_log_id);
            dbms_output.put_line('  Status    : ' || l_status);
            dbms_output.put_line('  Aan       : ' || l_to_address);

            if l_error_msg is not null then
                dbms_output.put_line('  Error     : ' || l_error_msg);
            end if;
        exception
            when no_data_found then
                dbms_output.put_line('  WAARSCHUWING: Mail log record niet gevonden voor ID ' || l_mail_log_id);
        end;
    else
        dbms_output.put_line('  WAARSCHUWING: Geen mail log ID teruggekomen!');
    end if;

    ---------------------------------------------------------------------------
    -- RESULTAAT
    ---------------------------------------------------------------------------
    dbms_output.put_line('');
    dbms_output.put_line('========================================');
    dbms_output.put_line('TEST SUCCESVOL');
    dbms_output.put_line('Totale duur: ' || extract(second from (systimestamp - l_total_start)) || 's');
    dbms_output.put_line('========================================');

exception
    when others then
        -- cleanup blob
        begin
            if l_pdf_blob is not null and dbms_lob.istemporary(l_pdf_blob) = 1 then
                dbms_lob.freetemporary(l_pdf_blob);
            end if;
        exception
            when others then null;
        end;
        --
        dbms_output.put_line('');
        dbms_output.put_line('========================================');
        dbms_output.put_line('TEST GEFAALD');
        dbms_output.put_line('========================================');
        dbms_output.put_line('Error code : ' || sqlcode);
        dbms_output.put_line('Error msg  : ' || sqlerrm);
        dbms_output.put_line('Backtrace  : ' || dbms_utility.format_error_backtrace);
        dbms_output.put_line('Totale duur: ' || extract(second from (systimestamp - l_total_start)) || 's');
        dbms_output.put_line('');
        dbms_output.put_line('Check ook:');
        dbms_output.put_line('  select * from icca_mail_log order by id desc fetch first 5 rows only;');
        dbms_output.put_line('  select * from logger_logs where scope like ''%audit_mail%'' order by id desc fetch first 10 rows only;');
        raise;
end;
/

undefine p_adt_id
undefine p_email
undefine p_use_dummy
