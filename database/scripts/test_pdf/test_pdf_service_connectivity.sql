/*
------------------------------------------------------------------------------
Naam      : test_pdf_service_connectivity.sql
Doel      : Test connectiviteit met de Node.js PDF service.
            Controleert de geconfigureerde URL en probeert een health check.
------------------------------------------------------------------------------
*/

set serveroutput on size unlimited;

declare
    l_pdf_service_url icca_app_config.config_value%type;
    l_url             varchar2(500);
    l_response        clob;
    l_status          number;
begin
    dbms_output.put_line('=== PDF SERVICE CONNECTIVITEIT TEST ===');

    -- 1. Haal geconfigureerde URL op
    begin
        select config_value
        into   l_pdf_service_url
        from   icca_app_config
        where  config_key = 'PDF_SERVICE_URL'
        and    active_ind = 'Y';
    exception
        when no_data_found then
            l_pdf_service_url := 'http://localhost:3000';
            dbms_output.put_line('Geen PDF_SERVICE_URL config gevonden, gebruik fallback: ' || l_pdf_service_url);
    end;

    dbms_output.put_line('Geconfigureerde PDF service URL: ' || l_pdf_service_url);

    -- 2. Test health endpoint (als beschikbaar)
    l_url := l_pdf_service_url || '/templates/refresh';
    dbms_output.put_line('Probeer endpoint: ' || l_url);

    begin
        apex_web_service.g_request_headers.delete;
        l_response := apex_web_service.make_rest_request(
            p_url         => l_url,
            p_http_method => 'GET'
        );
        l_status := apex_web_service.g_status_code;

        dbms_output.put_line('HTTP status: ' || l_status);
        dbms_output.put_line('Response: ' || substr(l_response, 1, 200));
    exception
        when others then
            dbms_output.put_line('FOUT bij aanroepen PDF service: ' || sqlerrm);
            dbms_output.put_line('Tip: controleer of de Node.js service draait en bereikbaar is vanuit de database.');
    end;

    dbms_output.put_line('=== EINDE TEST ===');
end;
/
