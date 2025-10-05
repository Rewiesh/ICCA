begin
    -- Define template for the module
    ords.define_template(   p_module_name => 'api'
                        ,   p_pattern     => 'postImage/'
                        );
end;
/
begin
    -- Handler for the endpoint
    ords.define_handler(    p_module_name   => 'api'
                        ,   p_pattern       => 'postImage/'
                        ,   p_method        => 'POST'
                        ,   p_source_type   => ords.source_type_plsql
                        ,   p_source        => q'[
declare
    v_audit_data  blob := :body;
    ln_ige_id     number;
    v_doc_id      number;
    v_username    varchar2(100);
    v_file_url    varchar2(500);
begin
    -- get user
    v_username := :username;

    -- set application context voor audit triggers
    dbms_session.set_identifier(v_username);

    -- store incoming message for logging purposes
    icca_incoming_msg.p_store_incoming_message(
        p_api_method   => 'POST',
        p_api_endpoint => 'api/postImage/ ',
        p_msg          => apex_util.blob_to_clob(v_audit_data, 'UTF-8'),
        po_ige_id      => ln_ige_id
    );

    -- schrijf bestand naar file system
    begin
        v_file_url := icca_file_upload.f_save_uploaded_file(
                p_blob      => v_audit_data
            ,   p_filename  => 'image.jpg'
            ,   p_mime_type => 'image/png'
        );
    exception
        when others then
            -- als file schrijven faalt, log de error maar ga door
            -- (zodat het ook werkt als maxapex de rechten nog niet heeft gefixt)
            v_file_url := null;
    end;

    -- insert the image into icca_documents
    insert into icca_documents (
            name
        ,   mime_type
        ,   image_data
        ,   file_url
    )
    values (
            'image.jpg'            -- Je kan dit dynamisch maken als je bestandsnaam meestuurt
        ,   'image/png'            -- idem: mime-type kan uit headers komen of extra veld
        ,   v_audit_data
        ,   v_file_url
    )
    returning id into v_doc_id;

    -- return the new ID as JSON
    owa_util.status_line (200, '', false);
    owa_util.mime_header ('application/json', true);
    --htp.prn('{"id": "' || v_doc_id || '"}');
    htp.prn('"' || v_doc_id || '"');
end;]'
                        );

    -- parameter: username
    ords.define_parameter(    p_module_name         => 'api'
                          ,   p_pattern             => 'postImage/'
                          ,   p_method              => 'POST'
                          ,   p_name                => 'X-Username'
                          ,   p_bind_variable_name  => 'username'
                          ,   p_source_type         => 'HEADER'
                          ,   p_param_type          => 'STRING'
                          );
    commit;
end;
/