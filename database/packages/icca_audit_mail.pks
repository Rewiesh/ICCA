create or replace package icca_audit_mail
as
    --
    -- Verstuur audit rapport mail naar meerdere ontvangers
    -- p_email_addresses: comma-separated email adressen
    procedure p_send_audit_report(
            p_adt_id            in number
        ,   p_email_addresses   in varchar2
    );
    --
    -- Genereer audit PDF via bestaande AOP infrastructuur
    function f_generate_audit_pdf( p_adt_id in number )
    return blob;
    --
end icca_audit_mail;
/