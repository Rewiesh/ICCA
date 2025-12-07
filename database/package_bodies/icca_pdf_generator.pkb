create or replace package body icca_pdf_generator as    
    --
    -- ========================================================================
    -- Package Body: icca_pdf_generator
    -- Versie: 1.0.0 - Fase 1
    -- ========================================================================
    --

    -- constanten
    c_pdf_service_url   constant varchar2(200) := 'http://localhost:3000';
    c_endpoint_template constant varchar2(200) := '/generate-pdf-template';
    c_endpoint_refresh  constant varchar2(200) := '/templates/refresh';

    --
    -- ========================================================================
    -- Private functions
    -- ========================================================================
    --

    --
    -- Valideer template naam tegen whitelist
    --
    function f_is_valid_template (
        p_template_name in varchar2
    ) return boolean is
    begin
        return p_template_name in ( 'BURO_HENNIE_DEKKER',
                                    'ICCA',
                                    'ICCA_ZONDER_CIJFERS',
                                    'FASE_CONTROL' );
    end f_is_valid_template;

    --
    -- ========================================================================
    -- Public functions
    -- ========================================================================
    --

    --
    -- Roep Node.js PDF service aan
    --
    function f_call_pdf_service (
        p_template_name in varchar2,
        p_json_data     in clob
    ) return blob is
        l_pdf_blob      blob;
        l_url           varchar2(500);
        l_response_code number;
    begin
        apex_debug.message(
            'f_call_pdf_service: template=%s',
            p_template_name
        );
        
        -- valideer template naam
        if not f_is_valid_template(p_template_name) then
            apex_debug.error(
            'Ongeldige template naam: %s',
            p_template_name
            );
            raise_application_error(
            -20003,
            'Ongeldige template naam: ' || p_template_name
            );
        end if;
        
        -- bouw url
        l_url := c_pdf_service_url || c_endpoint_template;
        apex_debug.info(
            'Calling PDF service: url=%s, json_size=%s',
            l_url,
            dbms_lob.getlength(p_json_data)
        );
        dbms_output.put_line('Calling PDF service: url='
                            || l_url
                            || ', json_size=' || dbms_lob.getlength(p_json_data));
        
        -- reset apex web service headers
        apex_web_service.g_request_headers.delete;
        
        -- set headers
        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json; charset=UTF-8';
        
        -- make request
        l_pdf_blob := apex_web_service.make_rest_request_b(
            p_url         => l_url,
            p_http_method => 'POST',
            p_body        => p_json_data
        );

        l_response_code := apex_web_service.g_status_code;
        apex_debug.info(
            'PDF service response: status=%s, size=%s bytes',
            l_response_code,
            nvl(
            dbms_lob.getlength(l_pdf_blob),
            0
            )
        );
        
        -- check response
        if l_response_code != 200 then
            apex_debug.error(
            'PDF service error: HTTP %s',
            l_response_code
            );
            raise_application_error(
            -20004,
            'PDF service error: HTTP ' || l_response_code
            );
        end if;

        if l_pdf_blob is null
        or dbms_lob.getlength(l_pdf_blob) < 100 then
            apex_debug.error('PDF generation failed: response te klein');
            raise_application_error(
            -20005,
            'PDF generation failed: response te klein ('
            || nvl(
                to_char(dbms_lob.getlength(l_pdf_blob)),
                'NULL'
            )
            || ' bytes)'
            );
        end if;

        return l_pdf_blob;
    exception
        when others then
            apex_debug.error(
            'Error in f_call_pdf_service: %s',
            sqlerrm
            );
            raise;
    end f_call_pdf_service;

    --
    -- Refresh template cache in Node.js service
    --
    procedure p_refresh_template_cache is
        l_url           varchar2(500);
        l_response      clob;
        l_response_code number;
    begin
        apex_debug.message('p_refresh_template_cache: start');
            
        -- bouw url
        l_url := c_pdf_service_url || c_endpoint_refresh;
        apex_debug.info(
            'Calling refresh endpoint: %s',
            l_url
        );
            
        -- reset headers
        apex_web_service.g_request_headers.delete;
            
        -- make request
        l_response := apex_web_service.make_rest_request(
            p_url         => l_url,
            p_http_method => 'GET'
        );
        l_response_code := apex_web_service.g_status_code;
        apex_debug.info(
            'Refresh response: status=%s, response=%s',
            l_response_code,
            substr(
            l_response,
            1,
            200
            )
        );
        if l_response_code != 200 then
            apex_debug.error(
            'Template refresh failed: HTTP %s',
            l_response_code
            );
            raise_application_error(
            -20006,
            'Template refresh failed: HTTP ' || l_response_code
            );
        end if;

        apex_debug.message('Template cache refreshed successfully');
    exception
        when others then
            apex_debug.error(
            'Error in p_refresh_template_cache: %s',
            sqlerrm
            );
            raise;
    end p_refresh_template_cache;

    --
    -- Hoofdfunctie: genereer PDF voor audit
    --
    function f_generate_audit_pdf (
        p_adt_id in number
    ) return blob is
        l_template_name varchar2(100);
        l_json_data     clob;
        l_pdf_blob      blob;
    begin
        apex_debug.message(
            'f_generate_audit_pdf: start for adt_id=%s',
            p_adt_id
        );
        
        -- haal template type op via client
        begin
            select  case 
                        when cnt.audit_report_type = 'ICCA_ZONDER_CIJFER' then 'ICCA_ZONDER_CIJFERS'
                        when cnt.audit_report_type = 'FASE_CONTROL' then 'FASE_CONTROL'
                        when cnt.audit_report_type = 'BURO_HENNIE_DEKKER' then 'BURO_HENNIE_DEKKER'
                        when cnt.audit_report_type = 'ICCA' then 'ICCA'
                            else 'ICCA'
                    end
            into    l_template_name
            from    icca_audits             adt
            join    icca_clients            cnt on cnt.id = adt.cnt_id
            join    icca_client_locations   cln on cln.id = adt.cln_id
            where   adt.id = p_adt_id;
            --
        exception
        when no_data_found then
            apex_debug.error(
                'Audit %s niet gevonden',
                p_adt_id
            );
            raise_application_error(
                -20007,
                'Audit niet gevonden: ' || p_adt_id
            );
        end;

        apex_debug.info(
            'Template type: %s',
            l_template_name
        );
        dbms_output.put_line('Template type: ' || l_template_name);
        
        -- bouw JSON op basis van template type
        l_json_data := case upper(trim(l_template_name))
            when 'BURO_HENNIE_DEKKER'   then icca_pdf_buro_hennie_dekker_data.f_get_main_json(p_adt_id)
            when 'ICCA'                 then icca_pdf_icca_data.f_get_main_json(p_adt_id)
            when 'ICCA_ZONDER_CIJFERS'  then icca_pdf_icca_zonder_cijfers_data.f_get_main_json(p_adt_id)
            when 'FASE_CONTROL'         then icca_pdf_fase_control_data.f_get_main_json(p_adt_id)
            else icca_pdf_icca_data.f_get_main_json(p_adt_id) -- fallback
        end;

        -- roep PDF service aan
        l_pdf_blob := f_call_pdf_service(
            l_template_name,
            l_json_data
        );

        apex_debug.message(
            'PDF generated successfully: %s bytes',
            dbms_lob.getlength(l_pdf_blob)
        );
        dbms_output.put_line('PDF generated successfully: '
                            || dbms_lob.getlength(l_pdf_blob) || ' bytes');

        return l_pdf_blob;
    exception
        when others then
            apex_debug.error(
                'Error in f_generate_audit_pdf: %s',
                sqlerrm
            );
            raise;
    end f_generate_audit_pdf;

end icca_pdf_generator;
/