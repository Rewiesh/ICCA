create or replace package body icca_mail
is
    --
    -- constants
    gc_crlf     constant varchar2(2) := utl_tcp.crlf;
    gc_boundary constant varchar2(50) := '----=_Boundary_ICCA_';
    --
    -----------------------------------------------------------------------------------------
    -- get config value
    function f_get_config(
        p_config_key in icca_mail_config.config_key%type
    ) return icca_mail_config.config_value%type
    is
        -- cursors
        cursor c_config(b_config_key in varchar2)
        is
            select config_value
            from   icca_mail_config
            where  config_key = b_config_key
            and    active_ind = 'Y';
        --
        -- variables
        l_config_value icca_mail_config.config_value%type;
    begin
        --
        open  c_config(b_config_key => p_config_key);
        fetch c_config into l_config_value;
        close c_config;
        --
        return l_config_value;
        --
    end f_get_config;
    --
    -----------------------------------------------------------------------------------------
    -- get mail template row
    function f_get_template_row(
        p_system_name in icca_mail_templates.system_name%type
    ) return icca_mail_templates%rowtype
    is
        -- cursors
        cursor c_template(b_system_name in varchar2)
        is
            select *
            from   icca_mail_templates
            where  system_name = b_system_name
            and    active_ind = 'Y';
        --
        -- variables
        lr_template icca_mail_templates%rowtype;
    begin
        --
        open  c_template(b_system_name => p_system_name);
        fetch c_template into lr_template;
        close c_template;
        --
        return lr_template;
        --
    end f_get_template_row;
    --
    -----------------------------------------------------------------------------------------
    -- open smtp connection
    function f_open_smtp_connection
    return utl_smtp.connection
    is
        l_connection    utl_smtp.connection;
        l_smtp_host     icca_mail_config.config_value%type;
        l_smtp_port     number;
        l_smtp_username icca_mail_config.config_value%type;
        l_smtp_password icca_mail_config.config_value%type;
    begin
        --
        -- get config values
        l_smtp_host     := f_get_config('SMTP_HOST');
        l_smtp_port     := to_number(f_get_config('SMTP_PORT'));
        l_smtp_username := f_get_config('SMTP_USERNAME');
        l_smtp_password := f_get_config('SMTP_PASSWORD');
        --
        -- open ssl connection
        l_connection := utl_smtp.open_connection(
            host => l_smtp_host,
            port => l_smtp_port,
            secure_connection_before_smtp => true
        );
        --
        -- authenticate
        utl_smtp.ehlo(l_connection, l_smtp_host);
        utl_smtp.auth(
            c        => l_connection,
            username => l_smtp_username,
            password => l_smtp_password,
            schemes  => utl_smtp.all_schemes
        );
        --
        return l_connection;
        --
    end f_open_smtp_connection;
    --
    -----------------------------------------------------------------------------------------
    -- log mail
    procedure p_log_mail(
            p_template_id           in number default null
        ,   p_to_address            in varchar2
        ,   p_from_address          in varchar2
        ,   p_subject               in varchar2
        ,   p_has_attachment        in varchar2 default 'N'
        ,   p_attachment_filename   in varchar2 default null
        ,   p_status                in varchar2
        ,   p_error_message         in varchar2 default null
        ,   po_log_id               out number
    )
    is
    begin
        --
        insert into icca_mail_log(
                template_id
            ,   to_address
            ,   from_address
            ,   subject
            ,   has_attachment
            ,   attachment_filename
            ,   status
            ,   error_message
            ,   sent_date
            ,   created_by
        ) values (
                p_template_id
            ,   p_to_address
            ,   p_from_address
            ,   p_subject
            ,   p_has_attachment
            ,   p_attachment_filename
            ,   p_status
            ,   p_error_message
            ,   case when p_status = 'SENT' then sysdate else null end
            ,   nvl(v('APP_USER'), user)
        ) 
        returning id into po_log_id;
        --
        commit;
        --
    exception
        when others then
            logger.log_error(
                p_text  => 'Error in p_log_mail',
                p_scope => 'icca_mail.p_log_mail',
                p_extra => 'TO=' || p_to_address || 
                          ', SUBJECT=' || p_subject ||
                          ', ERROR=' || sqlerrm ||
                          ', BACKTRACE=' || dbms_utility.format_error_backtrace
            );
    end p_log_mail;
    --
    -----------------------------------------------------------------------------------------
    -- send simple email
    procedure p_send_email(
            p_to                in sys.odcivarchar2list
        ,   p_cc                in sys.odcivarchar2list default null
        ,   p_bcc               in sys.odcivarchar2list default null
        ,   p_subject           in varchar2
        ,   p_mail_body         in clob
        ,   p_mail_body_content in varchar2 default 'plain'
        ,   po_log_id           out number
    )
    is
        l_connection    utl_smtp.connection;
        l_from          varchar2(100);
        l_to_list       varchar2(4000);
    begin
        --
        l_from := f_get_config('SMTP_FROM_ADDRESS');
        --
        l_connection := f_open_smtp_connection;
        utl_smtp.mail(l_connection, l_from);
        --
        -- ontvangers
        if p_to is not null and p_to.count > 0 then
            for idx in 1..p_to.count loop
                utl_smtp.rcpt(l_connection, p_to(idx));
                l_to_list := l_to_list || p_to(idx) || '; ';
            end loop;
        end if;
        --
        -- cc
        if p_cc is not null and p_cc.count > 0 then
            for idx in 1..p_cc.count loop
                utl_smtp.rcpt(l_connection, p_cc(idx));
            end loop;
        end if;
        --
        -- bcc
        if p_bcc is not null and p_bcc.count > 0 then
            for idx in 1..p_bcc.count loop
                utl_smtp.rcpt(l_connection, p_bcc(idx));
            end loop;
        end if;
        --
        -- headers
        utl_smtp.open_data(l_connection);
        utl_smtp.write_data(l_connection, 'Date: ' || to_char(sysdate, 'DD Mon YYYY HH24:MI:SS') || gc_crlf);
        utl_smtp.write_data(l_connection, 'From: ' || l_from || gc_crlf);
        utl_smtp.write_data(l_connection, 'Subject: ' || p_subject || gc_crlf);
        --
        -- to header
        if p_to is not null and p_to.count > 0 then
            utl_smtp.write_data(l_connection, 'To: ');
            for idx in 1..p_to.count loop
                utl_smtp.write_data(l_connection, p_to(idx) || ';');
            end loop;
            utl_smtp.write_data(l_connection, gc_crlf);
        end if;
        --
        -- mime
        utl_smtp.write_data(l_connection, 'MIME-Version: 1.0' || gc_crlf);
        utl_smtp.write_data(l_connection, 'Content-Type: multipart/alternative; boundary="' || gc_boundary || '"' || gc_crlf || gc_crlf);
        utl_smtp.write_data(l_connection, '--' || gc_boundary || gc_crlf);
        utl_smtp.write_data(l_connection, 'Content-Type: text/' || p_mail_body_content || '; charset="UTF-8"' || gc_crlf || gc_crlf);
        --
        -- body
        declare
            l_offset int := 1;
        begin
            loop
                exit when l_offset > dbms_lob.getlength(p_mail_body);
                utl_smtp.write_data(l_connection, dbms_lob.substr(p_mail_body, 255, l_offset));
                l_offset := l_offset + 255;
            end loop;
        end;
        --
        utl_smtp.write_data(l_connection, gc_crlf || gc_crlf);
        utl_smtp.write_data(l_connection, '--' || gc_boundary || '--' || gc_crlf);
        --
        utl_smtp.close_data(l_connection);
        utl_smtp.quit(l_connection);
        --
        p_log_mail(
            p_to_address   => rtrim(l_to_list, '; '),
            p_from_address => l_from,
            p_subject      => p_subject,
            p_status       => 'SENT',
            po_log_id      => po_log_id
        );
        --
    exception
        when others then
            begin
                utl_smtp.quit(l_connection);
            exception
                when others then null;
            end;
            --
            p_log_mail(
                p_to_address    => rtrim(l_to_list, '; '),
                p_from_address  => l_from,
                p_subject       => p_subject,
                p_status        => 'FAILED',
                p_error_message => sqlerrm,
                po_log_id       => po_log_id
            );
            --
            logger.log_error(
                p_text  => 'Error in p_send_email',
                p_scope => 'icca_mail.p_send_email',
                p_extra => 'ERROR=' || sqlerrm ||
                          ', BACKTRACE=' || dbms_utility.format_error_backtrace
            );
            raise;
    end p_send_email;
    --
    -----------------------------------------------------------------------------------------
    -- send email using template
    procedure p_send_template_email(
            p_template_name in icca_mail_templates.system_name%type
        ,   p_to            in sys.odcivarchar2list
        ,   p_param01       in varchar2 default null
        ,   p_param02       in varchar2 default null
        ,   p_param03       in varchar2 default null
        ,   p_param04       in varchar2 default null
        ,   p_param05       in varchar2 default null
        ,   p_param06       in varchar2 default null
        ,   p_param07       in varchar2 default null
        ,   p_param08       in varchar2 default null
        ,   p_param09       in varchar2 default null
        ,   p_param10       in varchar2 default null
        ,   po_log_id       out number
    )
    is
        -- variables
        lr_template  icca_mail_templates%rowtype;
        l_mail_body  clob;
        l_subject    varchar2(500);
    begin
        --
        lr_template := f_get_template_row(p_template_name);
        --
        l_subject := lr_template.subject;
        l_subject := regexp_replace(l_subject, '#P1#', p_param01);
        l_subject := regexp_replace(l_subject, '#P2#', p_param02);
        l_subject := regexp_replace(l_subject, '#P3#', p_param03);
        l_subject := regexp_replace(l_subject, '#P4#', p_param04);
        l_subject := regexp_replace(l_subject, '#P5#', p_param05);
        --
        l_mail_body := lr_template.body_html;
        l_mail_body := regexp_replace(l_mail_body, '#P1#', p_param01);
        l_mail_body := regexp_replace(l_mail_body, '#P2#', p_param02);
        l_mail_body := regexp_replace(l_mail_body, '#P3#', p_param03);
        l_mail_body := regexp_replace(l_mail_body, '#P4#', p_param04);
        l_mail_body := regexp_replace(l_mail_body, '#P5#', p_param05);
        l_mail_body := regexp_replace(l_mail_body, '#P6#', p_param06);
        l_mail_body := regexp_replace(l_mail_body, '#P7#', p_param07);
        l_mail_body := regexp_replace(l_mail_body, '#P8#', p_param08);
        l_mail_body := regexp_replace(l_mail_body, '#P9#', p_param09);
        l_mail_body := regexp_replace(l_mail_body, '#P10#', p_param10);
        --
        p_send_email(
            p_to                => p_to,
            p_subject           => l_subject,
            p_mail_body         => l_mail_body,
            p_mail_body_content => 'html',
            po_log_id           => po_log_id
        );
        --
        update icca_mail_log
        set    template_id = lr_template.id
        where  id = po_log_id;
        --
        commit;
        --
    exception
        when others then
            logger.log_error(
                p_text  => 'Error in p_send_template_email',
                p_scope => 'icca_mail.p_send_template_email',
                p_extra => 'TEMPLATE=' || p_template_name ||
                          ', ERROR=' || sqlerrm ||
                          ', BACKTRACE=' || dbms_utility.format_error_backtrace
            );
            raise;
    end p_send_template_email;
    --
    -----------------------------------------------------------------------------------------
    -- send email with pdf attachment
    procedure p_send_email_with_pdf(
            p_to                in sys.odcivarchar2list
        ,   p_subject           in varchar2
        ,   p_mail_body         in clob
        ,   p_mail_body_content in varchar2 default 'html'
        ,   p_pdf_blob          in blob
        ,   p_pdf_filename      in varchar2
        ,   po_log_id           out number
    )
    is
        l_connection    utl_smtp.connection;
        l_from          varchar2(100);
        l_to_list       varchar2(4000);
        l_offset        number := 1;
        l_step          pls_integer := 22800;
        l_raw_buffer    raw(32767);
    begin
        --
        l_from := f_get_config('SMTP_FROM_ADDRESS');
        --
        l_connection := f_open_smtp_connection;
        utl_smtp.mail(l_connection, l_from);
        --
        -- ontvangers
        if p_to is not null and p_to.count > 0 then
            for idx in 1..p_to.count loop
                utl_smtp.rcpt(l_connection, p_to(idx));
                l_to_list := l_to_list || p_to(idx) || '; ';
            end loop;
        end if;
        --
        -- headers
        utl_smtp.open_data(l_connection);
        utl_smtp.write_data(l_connection, 'Date: ' || to_char(sysdate, 'DD Mon YYYY HH24:MI:SS') || gc_crlf);
        utl_smtp.write_data(l_connection, 'From: ' || l_from || gc_crlf);
        utl_smtp.write_data(l_connection, 'Subject: ' || p_subject || gc_crlf);
        --
        -- to header
        if p_to is not null and p_to.count > 0 then
            utl_smtp.write_data(l_connection, 'To: ');
            for idx in 1..p_to.count loop
                utl_smtp.write_data(l_connection, p_to(idx) || ';');
            end loop;
            utl_smtp.write_data(l_connection, gc_crlf);
        end if;
        --
        utl_smtp.write_data(l_connection, 'MIME-Version: 1.0' || gc_crlf);
        utl_smtp.write_data(l_connection, 'Content-Type: multipart/mixed; boundary="' || gc_boundary || '"' || gc_crlf || gc_crlf);
        --
        -- mail body part
        utl_smtp.write_data(l_connection, '--' || gc_boundary || gc_crlf);
        utl_smtp.write_data(l_connection, 'Content-Type: text/' || p_mail_body_content || '; charset="UTF-8"' || gc_crlf || gc_crlf);
        --
        declare
            l_body_offset int := 1;
        begin
            loop
                exit when l_body_offset > dbms_lob.getlength(p_mail_body);
                utl_smtp.write_data(l_connection, dbms_lob.substr(p_mail_body, 255, l_body_offset));
                l_body_offset := l_body_offset + 255;
            end loop;
        end;
        --
        utl_smtp.write_data(l_connection, gc_crlf || gc_crlf);
        --
        -- pdf attachment
        utl_smtp.write_data(l_connection, '--' || gc_boundary || gc_crlf);
        utl_smtp.write_data(l_connection, 'Content-Type: application/pdf; name="' || p_pdf_filename || '"' || gc_crlf);
        utl_smtp.write_data(l_connection, 'Content-Transfer-Encoding: base64' || gc_crlf);
        utl_smtp.write_data(l_connection, 'Content-Disposition: attachment; filename="' || p_pdf_filename || '"' || gc_crlf || gc_crlf);
        --
        l_offset := 1;
        while l_offset <= dbms_lob.getlength(p_pdf_blob) loop
            if l_offset + l_step - 1 > dbms_lob.getlength(p_pdf_blob) then
                l_step := dbms_lob.getlength(p_pdf_blob) - l_offset + 1;
            end if;
            --
            dbms_lob.read(p_pdf_blob, l_step, l_offset, l_raw_buffer);
            utl_smtp.write_data(l_connection, utl_raw.cast_to_varchar2(utl_encode.base64_encode(l_raw_buffer)));
            --
            l_offset := l_offset + l_step;
        end loop;
        --
        utl_smtp.write_data(l_connection, gc_crlf);
        utl_smtp.write_data(l_connection, '--' || gc_boundary || '--' || gc_crlf);
        --
        utl_smtp.close_data(l_connection);
        utl_smtp.quit(l_connection);
        --
        p_log_mail(
            p_to_address          => rtrim(l_to_list, '; '),
            p_from_address        => l_from,
            p_subject             => p_subject,
            p_has_attachment      => 'Y',
            p_attachment_filename => p_pdf_filename,
            p_status              => 'SENT',
            po_log_id             => po_log_id
        );
        --
    exception
        when others then
            begin
                utl_smtp.quit(l_connection);
            exception
                when others then null;
            end;
            --
            p_log_mail(
                p_to_address    => rtrim(l_to_list, '; '),
                p_from_address  => l_from,
                p_subject       => p_subject,
                p_status        => 'FAILED',
                p_error_message => sqlerrm,
                po_log_id       => po_log_id
            );
            --
            logger.log_error(
                p_text  => 'Error in p_send_email_with_pdf',
                p_scope => 'icca_mail.p_send_email_with_pdf',
                p_extra => 'ERROR=' || sqlerrm ||
                          ', BACKTRACE=' || dbms_utility.format_error_backtrace
            );
            raise;
    end p_send_email_with_pdf;
    --
    -----------------------------------------------------------------------------------------
    -- send template email with pdf attachment
    procedure p_send_template_with_pdf(
            p_template_name in icca_mail_templates.system_name%type
        ,   p_to            in sys.odcivarchar2list
        ,   p_pdf_blob      in blob
        ,   p_pdf_filename  in varchar2
        ,   p_param01       in varchar2 default null
        ,   p_param02       in varchar2 default null
        ,   p_param03       in varchar2 default null
        ,   p_param04       in varchar2 default null
        ,   p_param05       in varchar2 default null
        ,   p_param06       in varchar2 default null
        ,   p_param07       in varchar2 default null
        ,   p_param08       in varchar2 default null
        ,   p_param09       in varchar2 default null
        ,   p_param10       in varchar2 default null
        ,   po_log_id       out number
    )
    is
        lr_template  icca_mail_templates%rowtype;
        l_subject    varchar2(500);
        l_mail_body  clob;
    begin
        --
        lr_template := f_get_template_row(p_template_name);
        --
        l_subject := lr_template.subject;
        l_subject := regexp_replace(l_subject, '#P1#', p_param01);
        l_subject := regexp_replace(l_subject, '#P2#', p_param02);
        l_subject := regexp_replace(l_subject, '#P3#', p_param03);
        l_subject := regexp_replace(l_subject, '#P4#', p_param04);
        l_subject := regexp_replace(l_subject, '#P5#', p_param05);
        --
        l_mail_body := lr_template.body_html;
        l_mail_body := regexp_replace(l_mail_body, '#P1#', p_param01);
        l_mail_body := regexp_replace(l_mail_body, '#P2#', p_param02);
        l_mail_body := regexp_replace(l_mail_body, '#P3#', p_param03);
        l_mail_body := regexp_replace(l_mail_body, '#P4#', p_param04);
        l_mail_body := regexp_replace(l_mail_body, '#P5#', p_param05);
        --
        p_send_email_with_pdf(
            p_to                => p_to,
            p_subject           => l_subject,
            p_mail_body         => l_mail_body,
            p_mail_body_content => 'html',
            p_pdf_blob          => p_pdf_blob,
            p_pdf_filename      => p_pdf_filename,
            po_log_id           => po_log_id
        );
        --
        update icca_mail_log
        set    template_id = lr_template.id
        where  id = po_log_id;
        --
        commit;
        --
    exception
        when others then
            logger.log_error(
                p_text  => 'Error in p_send_template_with_pdf',
                p_scope => 'icca_mail.p_send_template_with_pdf',
                p_extra => 'TEMPLATE=' || p_template_name ||
                          ', ERROR=' || sqlerrm ||
                          ', BACKTRACE=' || dbms_utility.format_error_backtrace
            );
            raise;
    end p_send_template_with_pdf;
    --
end icca_mail;
/