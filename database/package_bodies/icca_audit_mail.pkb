create or replace package body icca_audit_mail
as
    --
    -----------------------------------------------------------------------------------------
    -- Parse comma-separated email addresses naar collection (met validatie)
    function f_parse_email_addresses(
        p_email_string in varchar2
    ) return sys.odcivarchar2list
    is
        l_recipients    sys.odcivarchar2list := sys.odcivarchar2list();
        l_email         varchar2(255);
        l_start         number := 1;
        l_comma_pos     number;
        l_email_regex   constant varchar2(200) := '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';
    begin
        --
        if p_email_string is null then
            return l_recipients;
        end if;
        --
        apex_debug.message('Email string: ' || p_email_string);
        --
        -- Split op comma's en trim whitespace
        loop
            l_comma_pos := instr(p_email_string, ',', l_start);

            if l_comma_pos = 0 then
                -- Laatste email adres
                l_email := trim(substr(p_email_string, l_start));
                if l_email is not null then
                    -- Valideer email format
                    if regexp_like(l_email, l_email_regex) then
                        l_recipients.extend;
                        l_recipients(l_recipients.count) := l_email;
                    else
                        logger.log_warning(
                            p_text  => 'Ongeldig email adres genegeerd',
                            p_scope => 'icca_audit_mail.f_parse_email_addresses',
                            p_extra => 'EMAIL=' || l_email
                        );
                    end if;
                end if;
                exit;
            else
                -- Email adres voor de comma
                l_email := trim(substr(p_email_string, l_start, l_comma_pos - l_start));
                if l_email is not null then
                    -- Valideer email format
                    if regexp_like(l_email, l_email_regex) then
                        l_recipients.extend;
                        l_recipients(l_recipients.count) := l_email;
                    else
                        logger.log_warning(
                            p_text  => 'Ongeldig email adres genegeerd',
                            p_scope => 'icca_audit_mail.f_parse_email_addresses',
                            p_extra => 'EMAIL=' || l_email
                        );
                    end if;
                end if;
                l_start := l_comma_pos + 1;
            end if;
        end loop;
        --
        return l_recipients;
        --
    exception
        when others then
            logger.log_error(
                p_text  => 'Error in f_parse_email_addresses',
                p_scope => 'icca_audit_mail.f_parse_email_addresses',
                p_extra => 'EMAIL_STRING=' || p_email_string ||
                        ', ERROR=' || sqlerrm
            );
            return sys.odcivarchar2list();
    end f_parse_email_addresses;
    --
    -----------------------------------------------------------------------------------------
    -- Verstuur audit rapport mail naar meerdere ontvangers
    procedure p_send_audit_report(
            p_adt_id            in number
        ,   p_email_addresses   in varchar2
    )
    is
        -- cursors
        cursor c_get_audit_data( b_adt_id in number )
        is
            select  adt.id
            ,       adt.code
            ,       adt.audit_date
            ,       adt.last_control_date
            ,       cnt.company_name
            ,       cnt.contact_person       as cnt_contact_person
            ,       cln.name                 as location_name
            ,       cln.contact_person       as cln_contact_person
            from    icca_audits             adt
            join    icca_clients            cnt on cnt.id = adt.cnt_id
            join    icca_client_locations   cln on cln.id = adt.cln_id
            where   adt.id = b_adt_id
            ;

        -- variables
        lr_audit_data       c_get_audit_data%rowtype;
        l_recipients        sys.odcivarchar2list;
        l_pdf_blob          blob;
        l_pdf_filename      varchar2(255);
        l_contact_person    varchar2(255);
        l_mail_log_id       number;
        l_doc_id            number;
    begin
        --
        apex_debug.message('Email addresses: ' || p_email_addresses);
        dbms_output.put_line('Email addresses: ' || p_email_addresses);
        --
        -- Parse email adressen
        l_recipients := f_parse_email_addresses(p_email_addresses);
        apex_debug.message('Parsed email addresses: ' || l_recipients.count);
        dbms_output.put_line('Parsed email addresses: ' || l_recipients.count);
        --
        -- Voeg toe na het parsen van emails (regel ~100):
        if l_recipients.count = 0 then
            raise_application_error(-20002, 
                'Geen geldige email adressen gevonden. Controleer het formaat: naam@domein.nl');
        end if;
        --
        -- Log welke emails geaccepteerd zijn
        logger.log_info(
            p_text  => 'Email adressen geparsed',
            p_scope => 'icca_audit_mail.p_send_audit_report',
            p_extra => 'INPUT=' || p_email_addresses || 
                      ', VALID_COUNT=' || l_recipients.count
        );
        --
        apex_debug.message('Parsed email addresses count: ' || l_recipients.count);
        --
        -- Haal audit gegevens op
        open    c_get_audit_data( b_adt_id => p_adt_id );
        fetch   c_get_audit_data into lr_audit_data;

        if c_get_audit_data%notfound then
            close c_get_audit_data;
            raise_application_error(-20003, 'Audit niet gevonden: ' || p_adt_id);
            dbms_output.put_line('Audit niet gevonden: ' || p_adt_id);
        end if;

        close c_get_audit_data;
        --
        -- Bepaal contactpersoon
        l_contact_person := coalesce(
            lr_audit_data.cnt_contact_person,
            -- lr_audit_data.cln_contact_person,
            'geachte relatie'
        );
        dbms_output.put_line('Contact person: ' || l_contact_person);
        --
        -- Genereer PDF
        l_pdf_blob := icca_pdf_generator.f_generate_audit_pdf(p_adt_id => p_adt_id);
        dbms_output.put_line('PDF blob generated');
        --
        --
        -- Stel filename samen
        l_pdf_filename := lr_audit_data.code || '.' ||
                        lr_audit_data.company_name || '.' ||
                        lr_audit_data.location_name ||
                        '.pdf';

        --
        dbms_output.put_line('PDF filename: ' || l_pdf_filename);
        -- l_doc_id := icca_file_upload.f_save_and_register_document(
        --     p_blob          => l_pdf_blob
        -- ,   p_filename      => l_pdf_filename
        -- ,   p_mime_type     => 'application/pdf'
        -- );
        --
        dbms_output.put_line('Document ID: ' || l_doc_id);
        -- Update audit document
        -- update  icca_audits
        -- set     audit_doc_id = l_doc_id
        -- where   id = p_adt_id;
        --
        -- Verstuur mail
        icca_mail.p_send_template_with_pdf(
            p_template_name => 'AUDIT_REPORT_GENERATED',
            p_to            => l_recipients,
            p_pdf_blob      => l_pdf_blob,
            p_pdf_filename  => l_pdf_filename,
            p_param01       => lr_audit_data.code,
            p_param02       => lr_audit_data.location_name,
            p_param03       => to_char(lr_audit_data.last_control_date, 'DD-MM-YYYY'),
            p_param04       => l_contact_person,
            po_log_id       => l_mail_log_id
        );
        --
        -- Cleanup
        if l_pdf_blob is not null and dbms_lob.istemporary(l_pdf_blob) = 1 then
            dbms_lob.freetemporary(l_pdf_blob);
        end if;
        --
        -- Log success
        logger.log_info(
            p_text  => 'Audit rapport mail verstuurd vanuit APEX',
            p_scope => 'icca_audit_mail.p_send_audit_report',
            p_extra => 'ADT_ID=' || p_adt_id ||
                      ', CODE=' || lr_audit_data.code ||
                      ', RECIPIENTS=' || l_recipients.count ||
                      ', MAIL_LOG_ID=' || l_mail_log_id
        );

    exception
        when others then
            -- Cleanup
            begin
                if l_pdf_blob is not null and dbms_lob.istemporary(l_pdf_blob) = 1 then
                    dbms_lob.freetemporary(l_pdf_blob);
                end if;
            exception
                when others then null;
            end;
            --
            logger.log_error(
                p_text  => 'Error in p_send_audit_report',
                p_scope => 'icca_audit_mail.p_send_audit_report',
                p_extra => 'ADT_ID=' || p_adt_id ||
                          ', EMAILS=' || p_email_addresses ||
                          ', ERROR=' || sqlerrm ||
                          ', BACKTRACE=' || dbms_utility.format_error_backtrace
            );
            -- raise;
    end p_send_audit_report;
    --
end icca_audit_mail;
/
