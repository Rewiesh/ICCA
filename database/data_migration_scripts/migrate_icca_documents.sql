declare
    -- cursor to get old data IMAGES
    cursor c_get_old_data
    is
        select  img.ImageId             as old_image_id
        ,       img.ImageDataLocation   as filename
        ,       img.ImageMimeType       as mime_type
        from    Images img
        where   img.doc_id is null
        ;
    --
    -- variables
    type t_old_data is table of c_get_old_data%rowtype;
    --
    lt_old_data t_old_data;
    ln_doc_id number;
    ln_existing_doc_id number;
begin
    --
    -- get old data
    open    c_get_old_data;
    fetch   c_get_old_data bulk collect into lt_old_data;
    close   c_get_old_data;
    --
    for i in 1 .. lt_old_data.count 
    loop
        begin
            ln_doc_id := null;
            ln_existing_doc_id := null;
            
            -- **CHECK: Bestaat deze combinatie al in de nieuwe tabel?**
            begin
                select  id 
                into    ln_existing_doc_id
                from    icca_documents
                where   file_url = '/uploads/' || lt_old_data(i).filename
                and     rownum = 1;
            exception
                when no_data_found then
                    ln_existing_doc_id := null;
            end;
            
            -- Als record al bestaat, gebruik die doc_id
            if ln_existing_doc_id is not null then
                ln_doc_id := ln_existing_doc_id;
                dbms_output.put_line('Duplicate found - reusing doc_id: ' || ln_doc_id || ' for: ' || lt_old_data(i).filename);
            else
                -- Nieuw record aanmaken
                insert into icca_documents( name         
                                        ,   mime_type
                                        ,   file_url
                                        ,   migrated_data
                                    ) values (
                                        lt_old_data(i).filename
                                    ,   lt_old_data(i).mime_type
                                    ,   '/uploads/' || lt_old_data(i).filename
                                    ,   'Y'
                                    )
                        returning id into ln_doc_id;
                
                dbms_output.put_line('New document created - doc_id: ' || ln_doc_id || ' for: ' || lt_old_data(i).filename);
            end if;
            
            -- Update oude record met doc_id
            update  Images
            set     doc_id = ln_doc_id
            where   ImageId = lt_old_data(i).old_image_id;
            
        exception
            when others then
                dbms_output.put_line('Error migrating image: ' || rawtohex(lt_old_data(i).old_image_id) || ' - ' || sqlerrm);
                dbms_output.put_line('Filename: ' || lt_old_data(i).filename || ' - MimeType: ' || lt_old_data(i).mime_type);
                continue;
        end;
    end loop;
    
    commit;
    
    -- Summary
    dbms_output.put_line('---');
    dbms_output.put_line('Migration completed! Total records processed: ' || lt_old_data.count);
end;
/