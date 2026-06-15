SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE
    -- Mail gegevens
    c_to_addr       CONSTANT VARCHAR2(100) := 'diewish0@gmail.com';
    c_subject       CONSTANT VARCHAR2(200) := 'SMTP Test vanuit icca_mail package';
    c_message       CONSTANT VARCHAR2(4000) := 'Dit is een testmail verzonden met icca_mail.p_send_email.';
    
    v_log_id        NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== Mail Test Start ===');
    DBMS_OUTPUT.PUT_LINE('Versturen naar: ' || c_to_addr);
    
    icca_mail.p_send_email(
        p_to        => sys.odcivarchar2list(c_to_addr),
        p_subject   => c_subject,
        p_mail_body => to_clob(c_message),
        po_log_id   => v_log_id
    );
    
    DBMS_OUTPUT.PUT_LINE('✓ Mail succesvol verstuurd!');
    DBMS_OUTPUT.PUT_LINE('Log ID: ' || v_log_id);
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('=== ERROR ===');
        DBMS_OUTPUT.PUT_LINE('Error code: ' || SQLCODE);
        DBMS_OUTPUT.PUT_LINE('Error message: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Backtrace: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        RAISE;
END;
/