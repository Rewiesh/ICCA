create or replace package body icca_audit_file_upload
is

    -- Types voor interne mapping van images
    type t_image_map_rec is record (
        key     varchar2(200), -- FormId:ElemTypeId:ErrTypeId:Field
        doc_id  number
    );
    type tt_image_map is table of t_image_map_rec index by pls_integer;

    -----------------------------------------------------------------------------------------
    --  Helper: Convert CLOB (Base64) to BLOB
    function f_base64_to_blob( p_base64 in clob )
    return blob
    is
    begin
        return apex_web_service.clobbase642blob( p_base64 );
    end f_base64_to_blob;

    -----------------------------------------------------------------------------------------
    --  Helper: Parse Present Clients
    function f_get_present_clients( p_present_clients_json_arr in json_array_t  )
    return icca_audit_post_api.tt_present_clients
    is
        lr_present_clients icca_audit_post_api.tt_present_clients;
        l_client_obj       json_object_t;
        l_count            pls_integer;
    begin
        if p_present_clients_json_arr is null then return lr_present_clients; end if;
        
        l_count := p_present_clients_json_arr.get_size;
        for i in 0 .. l_count - 1 loop
            begin
                l_client_obj := treat( p_present_clients_json_arr.get(i) as json_object_t );
                lr_present_clients(i + 1).name := l_client_obj.get_string('name');
            exception when others then
                lr_present_clients(i + 1).name := p_present_clients_json_arr.get_string(i);
            end;
        end loop;
        return lr_present_clients;
    end f_get_present_clients;

    -----------------------------------------------------------------------------------------
    --  Helper: Parse KPI Elements
    function f_get_kpi_elements( p_kpi_elements_json_arr in json_array_t  )
    return icca_audit_post_api.tt_kpi_elements
    is
        lr_kpi_elements     icca_audit_post_api.tt_kpi_elements;
        l_count             pls_integer;
        l_kpi_element_obj   json_object_t;   
    begin
        if p_kpi_elements_json_arr is null then return lr_kpi_elements; end if;
        
        l_count := p_kpi_elements_json_arr.get_size;
        for i in 0 .. l_count - 1 loop
            l_kpi_element_obj := treat( p_kpi_elements_json_arr.get(i) as json_object_t );
            
            lr_kpi_elements(i + 1).id                := l_kpi_element_obj.get_number('Id');
            lr_kpi_elements(i + 1).audit_id          := l_kpi_element_obj.get_number('AuditId');
            lr_kpi_elements(i + 1).elements_audit_id := l_kpi_element_obj.get_number('elements_auditId');
            lr_kpi_elements(i + 1).elementLabel      := l_kpi_element_obj.get_string('ElementLabel');
            lr_kpi_elements(i + 1).elementValue      := l_kpi_element_obj.get_string('ElementValue');
            lr_kpi_elements(i + 1).elementComment    := l_kpi_element_obj.get_string('ElementComment');
        end loop;
        return lr_kpi_elements;        
    end f_get_kpi_elements;

    -----------------------------------------------------------------------------------------
    --  Helper: Parse Forms and Errors (injecting image IDs)
    function f_get_forms( 
        p_forms_json_arr in json_array_t,
        p_image_map      in tt_image_map
    )
    return icca_audit_post_api.tt_forms
    is
        lr_forms        icca_audit_post_api.tt_forms;
        l_form_obj      json_object_t;
        l_errors_arr    json_array_t;
        l_error_obj     json_object_t;
        l_error_rec     icca_audit_post_api.t_error;
        l_count         pls_integer;
        l_err_count     pls_integer;
        
        -- Helper vars for finding images
        l_form_id       number;
        l_elem_id       number;
        l_error_type_id number;
        l_key           varchar2(200);
        l_new_img_id    number;
    begin
        if p_forms_json_arr is null then return lr_forms; end if;
        
        l_count := p_forms_json_arr.get_size;
        for i in 0 .. l_count - 1 loop
            l_form_obj := treat( p_forms_json_arr.get(i) as json_object_t );
            
            -- Basic form data
            l_form_id                        := l_form_obj.get_number('Id'); 
            lr_forms(i + 1).id               := l_form_id;
            lr_forms(i + 1).floor_id         := l_form_obj.get_number('FloorId');
            lr_forms(i + 1).category_id      := l_form_obj.get_number('CategoryId');
            
            begin
                lr_forms(i + 1).form_date := cast( to_timestamp(replace(l_form_obj.get_string('Date'), 'Z', ''), 'YYYY-MM-DD"T"HH24:MI:SS.FF3') as date );
            exception when others then
                lr_forms(i + 1).form_date := sysdate; 
            end;
            
            lr_forms(i + 1).area_code        := l_form_obj.get_string('AreaCode');
            lr_forms(i + 1).counter_elements := l_form_obj.get_number('CounterElements');
            lr_forms(i + 1).remarks          := l_form_obj.get_string('Remarks');

            -- Nested errors
            l_errors_arr := l_form_obj.get_array('Errors');
            if l_errors_arr is not null then
                l_err_count := l_errors_arr.get_size;
                for j in 0 .. l_err_count - 1 loop
                    l_error_obj := treat( l_errors_arr.get(j) as json_object_t );
                    
                    l_elem_id       := l_error_obj.get_number('ElementTypeId');
                    l_error_type_id := l_error_obj.get_number('ErrorTypeId');
                    
                    l_error_rec.element_type_id          := l_elem_id;
                    l_error_rec.error_type_id            := l_error_type_id;
                    l_error_rec.log_book_remark          := l_error_obj.get_string('LogBook');
                    l_error_rec.technical_aspects_remark := l_error_obj.get_string('TechnicalAspects');
                    l_error_rec.error_count              := l_error_obj.get_number('Count');
                    
                    -- Look up Image IDs in our map
                    -- 1. Logbook Image
                    l_key := l_form_id || ':' || l_elem_id || ':' || l_error_type_id || ':logbook';
                    l_new_img_id := null;
                    
                    for k in 0 .. p_image_map.count - 1 loop
                        if p_image_map(k).key = l_key then
                            l_new_img_id := p_image_map(k).doc_id;
                            exit;
                        end if;
                    end loop;
                    l_error_rec.log_book_image_id := l_new_img_id;
                    
                    -- 2. Technical Aspects Image
                    l_key := l_form_id || ':' || l_elem_id || ':' || l_error_type_id || ':technicalaspects';
                    l_new_img_id := null;
                    
                    for k in 0 .. p_image_map.count - 1 loop
                        if p_image_map(k).key = l_key then
                            l_new_img_id := p_image_map(k).doc_id;
                            exit;
                        end if;
                    end loop;
                    l_error_rec.technical_aspects_image_id := l_new_img_id;
                    
                    -- Add to errors table
                    lr_forms(i + 1).error(j + 1) := l_error_rec;
                end loop;
            end if;
        end loop;
        return lr_forms;        
    end f_get_forms;

    -----------------------------------------------------------------------------------------
    --  Internal: Process the logic
    procedure p_internal_process(
        p_json_blob in blob
    )
    is
        l_json_obj          json_object_t;
        l_audit_obj         json_object_t;
        l_user_obj          json_object_t;
        l_images_arr        json_array_t;
        l_img_obj           json_object_t;
        l_img_trace         json_object_t;
        
        lr_audit            icca_audit_post_api.t_audit;
        t_img_map           tt_image_map;
        
        l_base64            clob;
        l_blob              blob;
        l_doc_id            number;
        l_unique_name       varchar2(200);
        l_key               varchar2(200);
        
        l_sig_base64        clob;
        
        l_username          varchar2(100);
        l_pfr_id            number;
        l_audit_id          number;
        l_completed         varchar2(1);
    begin
        -- 1. Parse BLOB to JSON object
        l_json_obj := json_object_t( p_json_blob );
        
        -- 2. Extract User and Get Pfr_ID
        begin
            l_user_obj := l_json_obj.get_object('user');
            if l_user_obj is not null then
                l_username := l_user_obj.get_string('username');
            end if;
            
            if l_username is not null and l_username != 'unknown' then
                -- Lookup logic from postAudits.sql
                select  pfr.id
                into    l_pfr_id
                from    icca_users      usr
                join    icca_performers pfr on pfr.usr_id = usr.id
                where   upper(username) = upper(l_username)
                fetch first row only;
                
                -- Set context for triggers
                dbms_session.set_identifier(l_username);
            else
                -- Fallback if no user in JSON? Or raise error?
                -- For now, let's allow it but pfr_id will be null.
                 l_pfr_id := null;
            end if;
        exception when others then
            l_pfr_id := null;
        end;
        
        -- 3. Get Audit Object & Duplicate Check
        l_audit_obj := l_json_obj.get_object('audit');
        l_audit_id  := l_audit_obj.get_number('Id');
        
        if l_audit_id is not null then
            begin
                select audit_completed
                into   l_completed
                from   icca_audits
                where  id = l_audit_id;
                
                if l_completed = 'Y' then
                    raise_application_error(-20002, 'Audit is already processed/completed.');
                end if;
            exception when no_data_found then
                -- Audit doesn't exist? That's weird for an update, but maybe it's a new one?
                -- Proceed.
                null;
            end;
        end if;

        -- 4. Process Images
        l_images_arr := l_json_obj.get_array('images');
        if l_images_arr is not null then
            for i in 0 .. l_images_arr.get_size - 1 loop
                l_img_obj := treat( l_images_arr.get(i) as json_object_t );
                
                -- Get Data
                l_base64 := l_img_obj.get_clob('imageData');
                
                if l_base64 is not null then
                    -- Decode
                    l_blob := f_base64_to_blob( l_base64 );
                    
                    -- Trace Info for key
                    l_img_trace := l_img_obj.get_object('traceImageData');
                    l_key := l_img_trace.get_number('FormId') || ':' || 
                             l_img_trace.get_number('ElementTypeId') || ':' || 
                             l_img_trace.get_number('ErrorTypeId') || ':' || 
                             l_img_trace.get_string('Field');
                             
                    -- Filename generation
                    l_unique_name := 'audit_img_' || sys_guid() || '.jpg';
                    
                    -- Save Image
                    l_doc_id := icca_file_upload.f_save_and_register_document(
                        p_blob          => l_blob,
                        p_filename      => l_unique_name,
                        p_mime_type     => 'image/jpeg' 
                    );
                    
                    -- Store in map
                    t_img_map(t_img_map.count).key := l_key;
                    t_img_map(t_img_map.count - 1).doc_id := l_doc_id;
                end if;
            end loop;
        end if;
        
        -- 5. Process Signature
        begin
            l_sig_base64 := l_audit_obj.get_clob('signature'); 
            if l_sig_base64 is not null then
                l_blob := f_base64_to_blob( l_sig_base64 );
                l_unique_name := 'audit_sig_' || l_audit_obj.get_string('Code') || '_' || sys_guid() || '.png';
                
                lr_audit.signature_image_id := icca_file_upload.f_save_and_register_document(
                    p_blob          => l_blob,
                    p_filename      => l_unique_name,
                    p_mime_type     => 'image/png'
                );
            end if;
        end;
        
        -- 6. Construct Audit Record
        lr_audit.id         := l_audit_id;
        lr_audit.code       := l_audit_obj.get_string('Code');
        
        begin
            lr_audit.audit_date := cast( to_timestamp(replace(l_audit_obj.get_string('DateTime'), 'Z', ''), 'YYYY-MM-DD"T"HH24:MI:SS.FF3') as date );
        exception when others then
            lr_audit.audit_date := sysdate;
        end;

        lr_audit.present_clients := f_get_present_clients( l_audit_obj.get_array('presentClients') ); 
        
        lr_audit.kpi_elements    := f_get_kpi_elements( l_audit_obj.get_array('elements') ); 
        
        -- Forms are top level
        lr_audit.forms           := f_get_forms( l_json_obj.get_array('forms'), t_img_map );
        
        -- 7. Call API
        icca_audit_post_api.p_process_audit(
            p_pfr_id => l_pfr_id,
            p_audit  => lr_audit
        );

    end p_internal_process;

    -----------------------------------------------------------------------------------------
    --  Async Logic: Submit Upload
    procedure p_submit_upload( 
        p_file_blob in blob,
        p_filename  in varchar2,
        p_cnt_id    in number,
        po_queue_id out number
    )
    is
        -- const
        c_program_name  constant varchar2(30) := 'ICCA_AUDIT_UPLOAD_PROG';
        
        -- vars
        l_job_name      varchar2(100);
        l_prog_exists   number;
    
        -- Inner proc to ensure program exists
        procedure p_ensure_program_exists is
        begin
             select count(*)
             into   l_prog_exists
             from   user_scheduler_programs
             where  program_name = c_program_name;
             
             if l_prog_exists = 0 then
                 dbms_scheduler.create_program(
                      program_name        => c_program_name
                    , program_type        => 'STORED_PROCEDURE'
                    , program_action      => 'icca_audit_file_upload.p_process_queue_item'
                    , number_of_arguments => 1
                    , enabled             => false
                    , comments            => 'Program to process audit upload queue items.'
                 );
                 
                 dbms_scheduler.define_program_argument(
                      program_name      => c_program_name
                    , argument_position => 1
                    , argument_type     => 'NUMBER'
                    , default_value     => null
                 );
                 
                 dbms_scheduler.enable(c_program_name);
             end if;
        exception when others then
             -- Ignore race conditions if program created by parallel session
             null;
        end p_ensure_program_exists;
        
    begin
        -- Insert into queue
        insert into icca_audit_upload_queue (
            filename,
            file_content,
            cnt_id,
            status,
            status_message
        ) values (
            p_filename,
            p_file_blob,
            p_cnt_id,
            'QUEUED',
            'Upload submitted.'
        ) returning id into po_queue_id;

        -- Commit to make data available for job
        commit;
        
        -- Ensure program definition
        p_ensure_program_exists;
        
        -- Create/Run job
        l_job_name := 'AUDIT_UPLOAD_' || po_queue_id;
        
        -- Clean up potential zombie job from failed previous attempt (unlikely with unique ID but good practice)
        begin
            dbms_scheduler.drop_job(l_job_name, force => true);
        exception when others then null;
        end;
        
        dbms_scheduler.create_job(
            job_name        => l_job_name,
            program_name    => c_program_name,
            start_date      => systimestamp, -- immediate
            enabled         => false,        -- enable after setting args
            auto_drop       => true,
            comments        => 'Async audit upload processing for ID ' || po_queue_id
        );
        
        dbms_scheduler.set_job_argument_value(
            job_name            => l_job_name,
            argument_position   => 1,
            argument_value      => po_queue_id
        );
        
        dbms_scheduler.enable(l_job_name);
        
    end p_submit_upload;

    -----------------------------------------------------------------------------------------
    --  Async Logic: Process Queue Item
    --  This procedure is called by DBMS_SCHEDULER
    procedure p_process_queue_item( 
        p_queue_id in number 
    )
    is
        l_blob          blob;
    begin
        -- 1. Lock/Get item
        update icca_audit_upload_queue
        set    status = 'PROCESSING',
               status_message = 'Started processing...'
        where  id = p_queue_id
        and    status = 'QUEUED' -- Safety check
        returning file_content into l_blob;
        
        if sql%rowcount = 0 then
            -- Already processed or not found
            return;
        end if;
        
        commit; -- Commit status change before long process
        
        -- 2. Process
        p_internal_process( l_blob );
        
        -- 3. Complete
        update icca_audit_upload_queue
        set    status = 'COMPLETED',
               status_message = 'Successfully processed.'
        where  id = p_queue_id;
        
        commit;
        
    exception when others then
        rollback; -- Rollback internal changes if any
        
        -- 4. Fail
        -- Clean up error message for user display
        declare
            l_msg varchar2(4000) := sqlerrm;
        begin
            -- Strip ORA-20xxx prefix for custom errors
            if l_msg like 'ORA-20%' then
               l_msg := regexp_replace(l_msg, '^ORA-20[0-9]{3}: ', '');
            end if;
            
            update icca_audit_upload_queue
            set    status = 'FAILED',
                   status_message = l_msg
            where  id = p_queue_id;
            commit;
        end;
    end p_process_queue_item;

end icca_audit_file_upload;
/
