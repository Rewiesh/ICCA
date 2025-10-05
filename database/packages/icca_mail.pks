create or replace package icca_mail is
    
    -- get config value
    function f_get_config(
        p_config_key in icca_mail_config.config_key%type
    ) return icca_mail_config.config_value%type;
    
    -- get mail template row
    function f_get_template_row(
        p_system_name in icca_mail_templates.system_name%type
    ) return icca_mail_templates%rowtype;
    
    -- send simple email
    procedure p_send_email(
            p_to                in sys.odcivarchar2list
        ,   p_cc                in sys.odcivarchar2list default null
        ,   p_bcc               in sys.odcivarchar2list default null
        ,   p_subject           in varchar2
        ,   p_mail_body         in clob
        ,   p_mail_body_content in varchar2 default 'plain'
        ,   po_log_id           out number
    );
    
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
    );
    
    -- send email with pdf attachment
    procedure p_send_email_with_pdf(
            p_to                in sys.odcivarchar2list
        ,   p_subject           in varchar2
        ,   p_mail_body         in clob
        ,   p_mail_body_content in varchar2 default 'html'
        ,   p_pdf_blob          in blob
        ,   p_pdf_filename      in varchar2
        ,   po_log_id           out number
    );
    
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
    );
    
end icca_mail;
/