create or replace package body icca_file_upload as

    --
    gc_upload_dir constant varchar2(50) := 'ICCA_UPLOADS';
    gc_config_key_pdf_url constant varchar2(100) := 'PDF_SERVICE_URL';
    gc_default_pdf_url    constant varchar2(100) := 'http://localhost:3000';
    --

    --
    -- Haal PDF service URL op uit icca_app_config
    --
    function f_get_pdf_service_url return varchar2 is
        l_pdf_service_url icca_app_config.config_value%type;
    begin
        select config_value
        into   l_pdf_service_url
        from   icca_app_config
        where  config_key = gc_config_key_pdf_url
        and    active_ind = 'Y';

        return nvl(l_pdf_service_url, gc_default_pdf_url);
    exception
        when no_data_found then
            return gc_default_pdf_url;
    end f_get_pdf_service_url;
    --

    function f_save_uploaded_file(
        p_blob          in blob
    ,   p_filename      in varchar2
    ,   p_mime_type     in varchar2 default 'image/png'
    ) 
    return varchar2
    is
        l_file              utl_file.file_type;
        l_buffer            raw(32767);
        l_amount            binary_integer := 32767;
        l_pos               integer := 1;
        l_blob_len          integer;
        l_unique_filename   varchar2(500);
        l_extension         varchar2(10);
        l_uuid              varchar2(100);
    begin
        -- Genereer unieke filename met UUID
        l_uuid := lower(replace(sys_guid(), '-', ''));
        
        -- Bepaal extensie uit mime_type of filename
        if p_filename like '%.%' then
            l_extension := substr(p_filename, instr(p_filename, '.', -1));
        elsif p_mime_type = 'image/png' then
            l_extension := '.png';
        elsif p_mime_type = 'image/jpeg' then
            l_extension := '.jpg';
        elsif p_mime_type = 'image/gif' then
            l_extension := '.gif';
        else
            l_extension := '.bin';
        end if;
        
        l_unique_filename := l_uuid || l_extension;
        
        -- Open file voor schrijven
        l_file := utl_file.fopen(
            location => gc_upload_dir
        ,   filename => l_unique_filename
        ,   open_mode => 'WB'
        ,   max_linesize => 32767
        );
        
        l_blob_len := dbms_lob.getlength(p_blob);
        
        -- Schrijf blob naar file in chunks
        while l_pos <= l_blob_len 
        loop
            if l_pos + l_amount - 1 > l_blob_len then
                l_amount := l_blob_len - l_pos + 1;
            end if;
            
            dbms_lob.read(p_blob, l_amount, l_pos, l_buffer);
            utl_file.put_raw(l_file, l_buffer, true);
            
            l_pos := l_pos + l_amount;
        end loop;
        
        -- Sluit file
        utl_file.fclose(l_file);
        
        -- Return de publieke URL
        return '/uploads/' || l_unique_filename;
        
    exception
        when others then
            if utl_file.is_open(l_file) then
                utl_file.fclose(l_file);
            end if;
            raise;
    end f_save_uploaded_file;
    --
    -----------------------------------------------------------------------------------------
    -- Save and register document
    function f_save_and_register_document(
        p_blob          in blob
    ,   p_filename      in varchar2
    ,   p_mime_type     in varchar2 default 'image/png'
    ,   p_document_name in varchar2 default null
    ) 
    return number
    is
        l_file_url      varchar2(500);
        l_doc_id        number;
        l_doc_name      varchar2(500);
    begin
        -- Stap 1: Upload bestand naar file system
        l_file_url := f_save_uploaded_file(
            p_blob      => p_blob
        ,   p_filename  => p_filename
        ,   p_mime_type => p_mime_type
        );
        
        -- Bepaal document naam
        l_doc_name := coalesce(p_document_name, p_filename);
        
        -- Stap 2: Insert in icca_documenten tabel
        insert into icca_documents (
                name
            ,   mime_type
            ,   file_url
            ,   file_name
        )
        values (
                l_doc_name
            ,   p_mime_type
            ,   l_file_url
            ,   regexp_substr(l_file_url, '[^/]+$')
        )
        returning id into l_doc_id;
        
        commit;
        
        return l_doc_id;
        
    exception
        when others then
            rollback;
            raise;
    end f_save_and_register_document;
    --
    -----------------------------------------------------------------------------------------
    -- Get document blob from file system
    function f_get_document_blob(
        p_document_id   in number
    ) 
    return blob
    is
        l_filename      varchar2(500);
        l_bfile         bfile;
        l_blob          blob;
        l_dest_offset   integer := 1;
        l_src_offset    integer := 1;
    begin
        -- Haal file_url op uit database
        select  file_name
        into    l_filename
        from    icca_documents
        where   id = p_document_id;
        
        -- Maak BFILE referentie
        l_bfile := bfilename(gc_upload_dir, l_filename);
        
        -- Create temporary BLOB
        dbms_lob.createtemporary(l_blob, true);
        
        -- Open en lees bestand
        dbms_lob.fileopen(l_bfile, dbms_lob.file_readonly);
        dbms_lob.loadblobfromfile(
            dest_lob    => l_blob,
            src_bfile   => l_bfile,
            amount      => dbms_lob.lobmaxsize,
            dest_offset => l_dest_offset,
            src_offset  => l_src_offset
        );
        dbms_lob.fileclose(l_bfile);
        
        return l_blob;
        
    exception
        when no_data_found then
            raise_application_error(-20001, 'Document met id ' || p_document_id || ' niet gevonden');
        when others then
            if dbms_lob.fileisopen(l_bfile) = 1 then
                dbms_lob.fileclose(l_bfile);
            end if;
            raise;
    end f_get_document_blob;
    --
    -----------------------------------------------------------------------------------------
    -- Convert BLOB to Base64 data URL
    function f_blob_to_base64_data_url(
        p_blob          in blob,
        p_mime_type     in varchar2 default 'image/jpeg'
    ) 
    return clob
    is
        l_clob          clob;
        l_step          pls_integer := 12000;  -- Must be divisible by 3 for base64
        l_offset        pls_integer := 1;
        l_amount        pls_integer := 12000;
        l_raw_chunk     raw(12000);
        l_base64_chunk  clob;
        l_blob_len      number;
    begin
        -- Create temporary CLOB
        dbms_lob.createtemporary(l_clob, true);
        
        -- Write data URL prefix
        dbms_lob.writeappend(l_clob, length('data:' || p_mime_type || ';base64,'), 'data:' || p_mime_type || ';base64,');
        
        -- Get blob length
        l_blob_len := dbms_lob.getlength(p_blob);
        
        -- Convert blob to base64 in chunks
        while l_offset <= l_blob_len loop
            -- Adjust amount for last chunk
            if l_offset + l_amount - 1 > l_blob_len then
                l_amount := l_blob_len - l_offset + 1;
            end if;
            
            -- Read chunk from blob
            dbms_lob.read(p_blob, l_amount, l_offset, l_raw_chunk);
            
            -- Convert to base64
            l_base64_chunk := utl_raw.cast_to_varchar2(utl_encode.base64_encode(l_raw_chunk));
            
            -- Append to result (removing line breaks added by base64_encode)
            l_base64_chunk := replace(l_base64_chunk, chr(10), '');
            l_base64_chunk := replace(l_base64_chunk, chr(13), '');
            dbms_lob.writeappend(l_clob, length(l_base64_chunk), l_base64_chunk);
            
            -- Move to next chunk
            l_offset := l_offset + l_amount;
        end loop;
        
        return l_clob;
        
    exception
        when others then
            if dbms_lob.istemporary(l_clob) = 1 then
                dbms_lob.freetemporary(l_clob);
            end if;
            raise;
    end f_blob_to_base64_data_url;
    --
    -----------------------------------------------------------------------------------------
    -- Get image base64 data
    function f_get_image_base64(
        p_file_path in varchar2
    ,   p_width     in number default 600
    ,   p_height    in number default 600
    ) return clob
    is
        l_response      clob;
        l_base64_data   clob;
    begin
        -- Call Node.js endpoint to get resized Base64 image
        l_response := apex_web_service.make_rest_request(
            p_url         => f_get_pdf_service_url || '/get-resized-base64',
            p_http_method => 'GET',
            p_parm_name   => apex_util.string_to_table('path:width:height'),
            p_parm_value  => apex_util.string_to_table(p_file_path || ':' || p_width || ':' || p_height)
        );
        
        -- Parse JSON response to extract base64_data field
        declare
            l_json_obj json_object_t;
        begin
            l_json_obj := json_object_t.parse(l_response);
            
            if l_json_obj.get_boolean('success') then
                l_base64_data := l_json_obj.get_clob('base64_data');
            else
                -- Return empty/default if error
                apex_debug.error('Failed to get base64 image: ' || l_json_obj.get_string('error'));
                return null;
            end if;
        end;
        
        return l_base64_data;
        
    exception
        when others then
            apex_debug.error('Error in f_get_image_base64: ' || sqlerrm);
            return null;
    end f_get_image_base64;

end icca_file_upload;
/