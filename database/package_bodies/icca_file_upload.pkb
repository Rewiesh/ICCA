create or replace package body icca_file_upload as

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
            location => 'ICCA_UPLOADS'
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
        )
        values (
                l_doc_name
            ,   p_mime_type
            ,   l_file_url
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
end icca_file_upload;
/