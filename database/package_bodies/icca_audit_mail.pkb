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
    -- -----------------------------------------------------------------------------------------
    -- -- Genereer audit PDF (dummy - vervang later door echte generatie)
    -- function f_generate_audit_pdf( p_adt_id in number )
    -- return blob
    -- is
    --     l_pdf_blob      blob;
    --     l_bfile         bfile;
    --     l_dest_offset   integer := 1;
    --     l_src_offset    integer := 1;
    -- begin
    --     --
    --     dbms_lob.createtemporary(l_pdf_blob, true);
    --     --
    --     l_bfile := bfilename('ICCA_UPLOADS', '10871.ASKO DC.AMS Test.pdf');
    --     dbms_lob.fileopen(l_bfile, dbms_lob.file_readonly);
    --     --
    --     dbms_lob.loadblobfromfile(
    --         dest_lob    => l_pdf_blob,
    --         src_bfile   => l_bfile,
    --         amount      => dbms_lob.lobmaxsize,
    --         dest_offset => l_dest_offset,
    --         src_offset  => l_src_offset
    --     );
    --     --
    --     dbms_lob.fileclose(l_bfile);
    --     --
    --     return l_pdf_blob;
    --     --
    -- exception
    --     when others then
    --         if dbms_lob.isopen(l_bfile) = 1 then
    --             dbms_lob.fileclose(l_bfile);
    --         end if;
    --         raise;
    -- end f_generate_audit_pdf;
    --
    -----------------------------------------------------------------------------------------
    -- Genereer audit PDF via bestaande AOP infrastructuur
    function f_generate_audit_pdf( p_adt_id in number )
    return blob
    is
        l_pdf_blob          blob;
        l_output_filename   varchar2(255);
        l_data_source       clob;
        l_binds             wwv_flow_plugin_util.t_bind_list;
    begin
        --
        -- Bepaal output filename
        l_output_filename := 'ICCA_Audit_' || p_adt_id || '.pdf';
        --
        -- Haal AOP data source SQL op (EXACT dezelfde als in je process)
        l_data_source := q'[
    with w_data as (
        select  aop_data
        ,       doc_ids
        from    icca_aop_report_data_vw
        where   adt_id = :P_ADT_ID
    )
    , w_all as(
        select  aop_data
        ,       doc_ids
        from    w_data
    )
    select  case when doc_ids is not null then json_transform (
                    aop_data
                ,   set '$.data[0].htmlContent' = icca_aop_pdf.f_get_imgs_html(doc_ids)
                    returning clob
            ) else aop_data end as aop_data
    from    w_all
    ]';
        --
        -- Bind parameter (HANDMATIG vullen)
        l_binds(1).name  := 'P_ADT_ID';
        l_binds(1).value := p_adt_id;
        --
        -- Roep AOP aan (EXACT zoals in je APEX process maar dan naar BLOB)
        l_pdf_blob := aop_api_pkg.plsql_call_to_aop(
            p_data_type       => aop_api_pkg.c_source_type_sql,
            p_data_source     => l_data_source,
            p_template_type   => aop_api_pkg.c_source_type_apex,
            p_template_source => 'rapportage_kwaliteitsmeting_template.docx',
            p_output_type     => aop_api_pkg.c_pdf_pdf,
            p_output_filename => l_output_filename,
            p_binds           => l_binds,
            p_aop_url         => 'https://api.apexofficeprint.com/',     -- Haal uit config
            p_api_key         => '361ACD26CA57F476E0637203000ACB44',  -- Haal uit config
            p_app_id          => 100 
        );
        --
        -- Log success
        logger.log_info(
            p_text  => 'Audit PDF gegenereerd via AOP',
            p_scope => 'icca_audit_mail.f_generate_audit_pdf',
            p_extra => 'ADT_ID=' || p_adt_id || 
                    ', SIZE=' || dbms_lob.getlength(l_pdf_blob) || ' bytes'
        );
        --
        return l_pdf_blob;
        --
    exception
        when others then
            logger.log_error(
                p_text  => 'Error in f_generate_audit_pdf',
                p_scope => 'icca_audit_mail.f_generate_audit_pdf',
                p_extra => 'ADT_ID=' || p_adt_id || 
                        ', ERROR=' || sqlerrm ||
                        ', BACKTRACE=' || dbms_utility.format_error_backtrace
            );
            raise;
    end f_generate_audit_pdf;    
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
    begin
        --
        apex_debug.message('Email addresses: ' || p_email_addresses);
        --
        -- Parse email adressen
        l_recipients := f_parse_email_addresses(p_email_addresses);
        apex_debug.message('Parsed email addresses: ' || l_recipients.count);
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
        end if;
        
        close c_get_audit_data;
        --
        -- Bepaal contactpersoon
        l_contact_person := coalesce(
            lr_audit_data.cln_contact_person,
            lr_audit_data.cnt_contact_person,
            'geachte relatie'
        );
        --
        -- Genereer PDF
        l_pdf_blob := f_generate_audit_pdf( p_adt_id => p_adt_id );
        --
        -- Stel filename samen
        l_pdf_filename := 'ICCA_Audit_' ||
                          lr_audit_data.code || '_' ||
                          replace(lr_audit_data.location_name, ' ', '_') ||
                          '.pdf';
        --
        -- Verstuur mail
        icca_mail.p_send_template_with_pdf(
            p_template_name => 'AUDIT_REPORT_GENERATED',
            p_to            => l_recipients,
            p_pdf_blob      => l_pdf_blob,
            p_pdf_filename  => l_pdf_filename,
            p_param01       => lr_audit_data.code,
            p_param02       => lr_audit_data.location_name,
            p_param03       => to_char(lr_audit_data.audit_date, 'DD-MM-YYYY'),
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
        
    -- exception
    --     when others then
    --         -- Cleanup
    --         begin
    --             if l_pdf_blob is not null and dbms_lob.istemporary(l_pdf_blob) = 1 then
    --                 dbms_lob.freetemporary(l_pdf_blob);
    --             end if;
    --         exception
    --             when others then null;
    --         end;
    --         --
    --         logger.log_error(
    --             p_text  => 'Error in p_send_audit_report',
    --             p_scope => 'icca_audit_mail.p_send_audit_report',
    --             p_extra => 'ADT_ID=' || p_adt_id ||
    --                       ', EMAILS=' || p_email_addresses ||
    --                       ', ERROR=' || sqlerrm ||
    --                       ', BACKTRACE=' || dbms_utility.format_error_backtrace
    --         );
    --         raise;
    end p_send_audit_report;
    --
end icca_audit_mail;
/