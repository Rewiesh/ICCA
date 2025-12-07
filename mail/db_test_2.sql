set serveroutput on size unlimited;

declare
    l_log_id number;
    l_to_list sys.odcivarchar2list;
begin
    --
    dbms_output.put_line('=== Test 1: Eenvoudige mail ===');
    --
    l_to_list := sys.odcivarchar2list('diewish0@gmail.com');
    --
    icca_mail.p_send_email(
        p_to        => l_to_list,
        p_subject   => 'Test vanuit ICCA Mail Package',
        p_body      => 'Dit is een testmail vanuit de icca_mail package.' || chr(10) || chr(10) ||
                       'Verzonden op: ' || to_char(sysdate, 'DD-MM-YYYY HH24:MI:SS'),
        po_log_id   => l_log_id
    );
    --
    dbms_output.put_line('Mail verzonden! Log ID: ' || l_log_id);
    dbms_output.put_line('');
    --
exception
    when others then
        dbms_output.put_line('Error in Test 1: ' || sqlerrm);
end;
/

declare
    l_log_id number;
begin
    --
    dbms_output.put_line('=== Test 2: Mail met HTML ===');
    --
    icca_mail.p_send_email(
        p_to        => 'diewish0@gmail.com',
        p_subject   => 'HTML Test vanuit ICCA',
        p_body      => 'Dit is de plain text versie van de mail.',
        p_body_html => '<html>
<body style="font-family: Arial, sans-serif; padding: 20px;">
    <h1 style="color: #4CAF50;">Test Mail</h1>
    <p>Dit is een <strong>HTML</strong> testmail vanuit de <em>icca_mail</em> package.</p>
    <table style="border-collapse: collapse; margin: 20px 0;">
        <tr style="background-color: #f2f2f2;">
            <td style="padding: 10px; border: 1px solid #ddd;">Verzonden op:</td>
            <td style="padding: 10px; border: 1px solid #ddd;">' || to_char(sysdate, 'DD-MM-YYYY HH24:MI:SS') || '</td>
        </tr>
    </table>
    <p style="color: #666;">Met vriendelijke groet,<br>ICCA Team</p>
</body>
</html>',
        po_log_id   => l_log_id
    );
    --
    dbms_output.put_line('HTML mail verzonden! Log ID: ' || l_log_id);
    dbms_output.put_line('');
    --
exception
    when others then
        dbms_output.put_line('Error in Test 2: ' || sqlerrm);
end;
/

declare
    l_log_id number;
begin
    --
    dbms_output.put_line('=== Test 3: Template mail (LOGBOOK_CREATED) ===');
    --
    icca_mail.p_send_template_email(
        p_template_name => 'LOGBOOK_CREATED',
        p_to            => 'diewish0@gmail.com',
        p_param01       => 'Test Logboek Entry',
        p_param02       => to_char(sysdate, 'DD-MM-YYYY'),
        p_param03       => 'Rewiesh Chitan',
        p_param04       => 'https://icca-dashboard.maxapex.net/ords/r/icca_dashboard/icca-dashboard/home',
        po_log_id       => l_log_id
    );
    --
    dbms_output.put_line('Template mail verzonden! Log ID: ' || l_log_id);
    dbms_output.put_line('');
    --
exception
    when others then
        dbms_output.put_line('Error in Test 3: ' || sqlerrm);
end;
/

declare
    l_log_id number;
begin
    --
    dbms_output.put_line('=== Test 4: Mail met CC en BCC ===');
    --
    icca_mail.p_send_email(
        p_to        => 'diewish0@gmail.com',
        p_cc        => 'info@iccaadvies.eu',
        p_subject   => 'Test met CC',
        p_body      => 'Deze mail heeft een CC ontvanger.',
        po_log_id   => l_log_id
    );
    --
    dbms_output.put_line('Mail met CC verzonden! Log ID: ' || l_log_id);
    dbms_output.put_line('');
    --
exception
    when others then
        dbms_output.put_line('Error in Test 4: ' || sqlerrm);
end;
/

declare
    l_log_id number;
begin
    --
    dbms_output.put_line('=== Test 5: Meerdere ontvangers ===');
    --
    icca_mail.p_send_email_multiple(
        p_to_list   => sys.odcivarchar2list('diewish0@gmail.com', 'info@iccaadvies.eu'),
        p_subject   => 'Test naar meerdere ontvangers',
        p_body      => 'Deze mail gaat naar meerdere ontvangers.',
        po_log_id   => l_log_id
    );
    --
    dbms_output.put_line('Mail naar meerdere ontvangers verzonden! Log ID: ' || l_log_id);
    dbms_output.put_line('');
    --
exception
    when others then
        dbms_output.put_line('Error in Test 5: ' || sqlerrm);
end;
/

-- bekijk de resultaten
select id,
       to_address,
       subject,
       status,
       sent_date,
       error_message
from   icca_mail_log
order  by created_date desc
fetch  first 5 rows only;