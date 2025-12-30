SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE
    -- SMTP Configuratie
    c_smtp_host     CONSTANT VARCHAR2(100) := 'smtp.transip.email';
    c_smtp_port     CONSTANT NUMBER := 465;  -- SSL poort
    -- c_username      CONSTANT VARCHAR2(100) := 'info@iccaadvies.eu';
    c_username      CONSTANT VARCHAR2(100) := 'kwaliteit@iccaadvies.eu';
    -- c_password      CONSTANT VARCHAR2(100) := 'zyrpeb-nipraF-9fyppo';
    c_password      CONSTANT VARCHAR2(100) := 'Carla412jaguar';
    
    -- Mail gegevens
    -- c_from_addr     CONSTANT VARCHAR2(100) := 'info@iccaadvies.eu';
    c_from_addr     CONSTANT VARCHAR2(100) := 'kwaliteit@iccaadvies.eu';
    c_to_addr       CONSTANT VARCHAR2(100) := 'diewish0@gmail.com';
    c_subject       CONSTANT VARCHAR2(200) := 'SMTP Test vanuit Oracle';
    c_message       CONSTANT VARCHAR2(4000) := 'Dit is een testmail verzonden vanuit Oracle Database.';
    
    -- Connectie variabelen
    v_connection    UTL_SMTP.connection;
    v_crlf          VARCHAR2(2) := UTL_TCP.crlf;
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== SMTP Test Start ===');
    DBMS_OUTPUT.PUT_LINE('Server: ' || c_smtp_host || ':' || c_smtp_port);
    
    -- Stap 1: Open SSL connectie
    DBMS_OUTPUT.PUT_LINE('Stap 1: Opening SSL connection...');
    v_connection := UTL_SMTP.open_connection(
        host => c_smtp_host,
        port => c_smtp_port,
        secure_connection_before_smtp => TRUE  -- Direct SSL (poort 465)
    );
    DBMS_OUTPUT.PUT_LINE('✓ Connection opened');
    
    -- Stap 2: EHLO
    DBMS_OUTPUT.PUT_LINE('Stap 2: Sending EHLO...');
    UTL_SMTP.ehlo(v_connection, c_smtp_host);
    DBMS_OUTPUT.PUT_LINE('✓ EHLO successful');
    
    -- Stap 3: Authenticatie
    DBMS_OUTPUT.PUT_LINE('Stap 3: Authenticating...');
    UTL_SMTP.auth(
        c        => v_connection,
        username => c_username,
        password => c_password,
        schemes  => UTL_SMTP.all_schemes
    );
    DBMS_OUTPUT.PUT_LINE('✓ Authentication successful');
    
    -- Stap 4: MAIL FROM
    DBMS_OUTPUT.PUT_LINE('Stap 4: Setting sender...');
    UTL_SMTP.mail(v_connection, c_from_addr);
    DBMS_OUTPUT.PUT_LINE('✓ Sender set');
    
    -- Stap 5: RCPT TO
    DBMS_OUTPUT.PUT_LINE('Stap 5: Setting recipient...');
    UTL_SMTP.rcpt(v_connection, c_to_addr);
    DBMS_OUTPUT.PUT_LINE('✓ Recipient set');
    
    -- Stap 6: DATA - Verstuur mail headers en body
    DBMS_OUTPUT.PUT_LINE('Stap 6: Sending message...');
    UTL_SMTP.open_data(v_connection);
    
    UTL_SMTP.write_data(v_connection, 'Date: ' || TO_CHAR(SYSDATE, 'DD Mon YYYY HH24:MI:SS') || v_crlf);
    UTL_SMTP.write_data(v_connection, 'From: ' || c_from_addr || v_crlf);
    UTL_SMTP.write_data(v_connection, 'To: ' || c_to_addr || v_crlf);
    UTL_SMTP.write_data(v_connection, 'Subject: ' || c_subject || v_crlf);
    UTL_SMTP.write_data(v_connection, 'Content-Type: text/plain; charset=UTF-8' || v_crlf);
    UTL_SMTP.write_data(v_connection, v_crlf);  -- Lege regel tussen headers en body
    UTL_SMTP.write_data(v_connection, c_message || v_crlf);
    
    UTL_SMTP.close_data(v_connection);
    DBMS_OUTPUT.PUT_LINE('✓ Message sent');
    
    -- Stap 7: Sluit connectie
    DBMS_OUTPUT.PUT_LINE('Stap 7: Closing connection...');
    UTL_SMTP.quit(v_connection);
    DBMS_OUTPUT.PUT_LINE('✓ Connection closed');
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TEST SUCCESVOL ===');
    DBMS_OUTPUT.PUT_LINE('Mail verzonden naar: ' || c_to_addr);
    
--EXCEPTION
--    WHEN UTL_SMTP.transient_error OR UTL_SMTP.permanent_error THEN
--        DBMS_OUTPUT.PUT_LINE('');
--        DBMS_OUTPUT.PUT_LINE('=== SMTP ERROR ===');
--        DBMS_OUTPUT.PUT_LINE('Error code: ' || SQLCODE);
--        DBMS_OUTPUT.PUT_LINE('Error message: ' || SQLERRM);
--        
--        BEGIN
--            UTL_SMTP.quit(v_connection);
--        EXCEPTION
--            WHEN OTHERS THEN NULL;
--        END;
--        
--        RAISE;
--        
--    WHEN OTHERS THEN
--        DBMS_OUTPUT.PUT_LINE('');
--        DBMS_OUTPUT.PUT_LINE('=== GENERAL ERROR ===');
--        DBMS_OUTPUT.PUT_LINE('Error code: ' || SQLCODE);
--        DBMS_OUTPUT.PUT_LINE('Error message: ' || SQLERRM);
--        
--        BEGIN
--            UTL_SMTP.quit(v_connection);
--        EXCEPTION
--            WHEN OTHERS THEN NULL;
--        END;
--        
--        RAISE;
END;
/