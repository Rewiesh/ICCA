/*
------------------------------------------------------------------------------
Naam      : test_pdf_docker_connectivity.sql
Doel      : Test verschillende mogelijke URL's voor de PDF service in de nieuwe
            Dockerized database omgeving.
            Na de migratie kan localhost niet meer de host server zijn.
------------------------------------------------------------------------------
*/

set serveroutput on size unlimited;

declare
    type t_url_list is table of varchar2(500);
    l_urls t_url_list := t_url_list(
        'http://localhost:3000/templates/refresh',
        'http://127.0.0.1:3000/templates/refresh',
        'http://icca-dashboard.maxapex.net:3000/templates/refresh',
        'http://host.docker.internal:3000/templates/refresh',
        'http://172.17.0.1:3000/templates/refresh'
    );
    l_response clob;
    l_status   number;
begin
    dbms_output.put_line('=== PDF SERVICE DOCKER CONNECTIVITEIT TEST ===');

    for i in 1 .. l_urls.count
    loop
        dbms_output.put_line('');
        dbms_output.put_line('Test URL: ' || l_urls(i));

        begin
            apex_web_service.g_request_headers.delete;
            l_response := apex_web_service.make_rest_request(
                p_url         => l_urls(i),
                p_http_method => 'GET'
            );
            l_status := apex_web_service.g_status_code;

            dbms_output.put_line('  HTTP status: ' || l_status);
            dbms_output.put_line('  Response: ' || substr(l_response, 1, 100));
        exception
            when others then
                dbms_output.put_line('  FOUT: ' || sqlerrm);
        end;
    end loop;

    dbms_output.put_line('');
    dbms_output.put_line('=== EINDE TEST ===');
end;
/
