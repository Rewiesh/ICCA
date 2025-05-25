create or replace package body icca_audit_post_api
is
    /*
        Start: Fill types function
    */
    --
    -----------------------------------------------------------------------------------------
    --  convert: Present Clients Error Json Object
    function f_get_present_clients( p_present_clients_json_arr in json_array_t  )
    return tt_present_clients
    is
        -- variables
        lr_present_clients tt_present_clients;
        l_count            pls_integer;
    begin
        --
        if p_present_clients_json_arr is null 
        then    
            --
            return lr_present_clients;
            --
        end if;
        --        
        l_count := p_present_clients_json_arr.get_size;
        --
        for i in 0 .. l_count - 1 
        loop
            --
            lr_present_clients(i + 1).name := p_present_clients_json_arr.get_string(i);
            --
        end loop;
        --
        return lr_present_clients;
        --
    end f_get_present_clients;
    --
    -----------------------------------------------------------------------------------------
    --  convert: KPI Elements Error Json Object
    function f_get_kpi_elements( p_kpi_elements_json_arr in json_array_t  )
    return tt_kpi_elements
    is
        -- variables
        lr_kpi_elements     tt_kpi_elements;
        l_count             pls_integer;
        l_kpi_element_obj   json_object_t;   
    begin
        --
        if p_kpi_elements_json_arr is null 
        then
            --
            return lr_kpi_elements;
            --
        end if;
        --
        l_count := p_kpi_elements_json_arr.get_size;
        --
        for i in 0 .. l_count - 1 
        loop
            --
            l_kpi_element_obj := treat( p_kpi_elements_json_arr.get(i) as json_object_t );
            --
            lr_kpi_elements(i + 1).id                := l_kpi_element_obj.get_number('Id');
            lr_kpi_elements(i + 1).audit_id          := l_kpi_element_obj.get_number('AuditId');
            lr_kpi_elements(i + 1).elements_audit_id := l_kpi_element_obj.get_number('elements_auditId');
            lr_kpi_elements(i + 1).elementLabel      := l_kpi_element_obj.get_string('ElementLabel');
            lr_kpi_elements(i + 1).elementValue      := l_kpi_element_obj.get_string('ElementValue');
            lr_kpi_elements(i + 1).elementComment    := l_kpi_element_obj.get_string('ElementComment');
            --
        end loop;
        --
        return lr_kpi_elements;        
        --        
    end f_get_kpi_elements;
    --
    -----------------------------------------------------------------------------------------
    --  convert: FORMS Error Json Object
    function f_get_form_errors(p_errors_json_arr in json_array_t)
    return tt_error
    is
        -- variables
        lr_errors     tt_error;
        l_error_obj   json_object_t;
        l_count       pls_integer;
    begin
        --
        if p_errors_json_arr is null 
        then
            --
            return lr_errors;
            --
        end if;
        --
        l_count := p_errors_json_arr.get_size;
        --
        for i in 0 .. l_count - 1 
        loop
            --LogbookImageId
            l_error_obj := treat( p_errors_json_arr.get(i) as json_object_t );
            --
            lr_errors(i + 1).element_type_id            := l_error_obj.get_number('ElementTypeId');
            lr_errors(i + 1).error_type_id              := l_error_obj.get_number('ErrorTypeId');
            lr_errors(i + 1).log_book_remark            := l_error_obj.get_string('LogBook');
            lr_errors(i + 1).log_book_image_id          := l_error_obj.get_string('LogbookImageId');
            lr_errors(i + 1).technical_aspects_remark   := l_error_obj.get_string('TechnicalAspects');
            lr_errors(i + 1).technical_aspects_image_id := l_error_obj.get_string('TechnicalAspectsImageId');
            lr_errors(i + 1).error_count                := l_error_obj.get_number('Count');
            --
        end loop;
        --
        return lr_errors;
        --
    end f_get_form_errors;
    --
    -----------------------------------------------------------------------------------------
    --  convert: FORMS Json Object
    function f_get_forms( p_forms_json_arr  in json_array_t  )
    return tt_forms
    is
        -- variables
        lr_forms       tt_forms;
        l_form_obj     json_object_t;
        l_count        pls_integer;
        l_form_date    timestamp;  
    begin
        --
        if p_forms_json_arr is null 
        then
            --
            return lr_forms;
            --
        end if;
        --
        l_count := p_forms_json_arr.get_size;
        --
        for i in 0 .. l_count - 1 
        loop
            --
            l_form_obj := treat( p_forms_json_arr.get(i) as json_object_t );
            --
            -- lr_forms(i + 1).id               := to_number(l_form_obj.get_string('Id')); -- UUID naar NUMBER (aanpassen als dit string moet zijn)
            lr_forms(i + 1).floor_id         := l_form_obj.get_number('FloorId');
            lr_forms(i + 1).category_id      := l_form_obj.get_number('CategoryId');
            lr_forms(i + 1).form_date        := cast( to_timestamp(replace(l_form_obj.get_string('Date'), 'Z', ''), 'YYYY-MM-DD"T"HH24:MI:SS.FF3') as date );
            lr_forms(i + 1).area_code        := l_form_obj.get_string('AreaCode');
            lr_forms(i + 1).counter_elements := l_form_obj.get_number('CounterElements');
            lr_forms(i + 1).remarks          := l_form_obj.get_string('Remarks');

            -- Nested errors
            lr_forms(i + 1).error := f_get_form_errors(l_form_obj.get_array('Errors'));
            --
        end loop;
        --
        return lr_forms;        
        --        
    end f_get_forms;    
    --
    -----------------------------------------------------------------------------------------
    --  convert: AUDIT Json Object 
    function f_audit_values( p_audit_json_obj in json_object_t )
    return t_audit
    is
        -- variables
        lr_audit    t_audit;
        l_audit_obj json_object_t;
    begin
        --
        l_audit_obj := p_audit_json_obj.get_object('audit');
        --
        lr_audit.id                 := l_audit_obj.get_number( 'Id' );
        lr_audit.code               := l_audit_obj.get_string( 'Code' );
        lr_audit.audit_date         := cast( to_timestamp(replace(l_audit_obj.get_string('DateTime'), 'Z', ''), 'YYYY-MM-DD"T"HH24:MI:SS.FF3')  as date);
        lr_audit.signature_image_id := l_audit_obj.get_string( 'SignatureImageId' );
        --
        lr_audit.present_clients    := f_get_present_clients( l_audit_obj.get_array('PresentClients') );
        --
        lr_audit.kpi_elements       := f_get_kpi_elements( l_audit_obj.get_array('Elements') );
        --
        lr_audit.forms              := f_get_forms( p_audit_json_obj.get_array('forms') );
        --
        return lr_audit;
        --
    end f_audit_values;
    --
    -----------------------------------------------------------------------------------------
    --
    /*
        End: Fill types function
    */    
    --
    -----------------------------------------------------------------------------------------
    --  process de ingekomen audit gegevens
    procedure p_dbms_output_record( p_audit in t_audit )
    is
    begin
        dbms_output.put_line('p_audit.id                : '|| p_audit.id);
        dbms_output.put_line('p_audit.code              : '|| p_audit.code);
        dbms_output.put_line('p_audit.audit_date        : '|| to_char(p_audit.audit_date, 'YYYY-MM-DD"T"HH24:MI:SS'));
        dbms_output.put_line('p_audit.signature_image_id: '|| p_audit.signature_image_id);
        --
        if ( p_audit.present_clients.count > 0 )
        then
            --
            for i in 1..p_audit.present_clients.count
            loop
                --
                dbms_output.put_line('p_audit.present_clients('||i||').name: '||p_audit.present_clients(i).name);
                --
            end loop;
            --
        else
            --
            dbms_output.put_line('p_audit.present_clients   : {}');
            --
        end if;
        --
        -- KPI Elements
        if p_audit.kpi_elements.count > 0 
        then
            for i in 1..p_audit.kpi_elements.count 
            loop
                dbms_output.put_line('p_audit.kpi_elements('||i||').id               : '||p_audit.kpi_elements(i).id);
                dbms_output.put_line('p_audit.kpi_elements('||i||').audit_id         : '||p_audit.kpi_elements(i).audit_id);
                dbms_output.put_line('p_audit.kpi_elements('||i||').elements_audit_id: '||p_audit.kpi_elements(i).elements_audit_id);
                dbms_output.put_line('p_audit.kpi_elements('||i||').elementLabel     : '||p_audit.kpi_elements(i).elementLabel);
                dbms_output.put_line('p_audit.kpi_elements('||i||').elementValue     : '||p_audit.kpi_elements(i).elementValue);
                dbms_output.put_line('p_audit.kpi_elements('||i||').elementComment   : '||p_audit.kpi_elements(i).elementComment);
            end loop;
        else
            dbms_output.put_line('p_audit.kpi_elements       : []');
        end if;
        -- Forms
        if p_audit.forms.count > 0 
        then
            for i in 1 .. p_audit.forms.count 
            loop
                dbms_output.put_line('p_audit.forms('||i||').id               : '||p_audit.forms(i).id);
                dbms_output.put_line('p_audit.forms('||i||').floor_id         : '||p_audit.forms(i).floor_id);
                dbms_output.put_line('p_audit.forms('||i||').category_id      : '||p_audit.forms(i).category_id);
                dbms_output.put_line('p_audit.forms('||i||').form_date        : '||to_char(p_audit.forms(i).form_date, 'YYYY-MM-DD"T"HH24:MI:SS'));
                dbms_output.put_line('p_audit.forms('||i||').area_code        : '||p_audit.forms(i).area_code);
                dbms_output.put_line('p_audit.forms('||i||').counter_elements : '||p_audit.forms(i).counter_elements);
                dbms_output.put_line('p_audit.forms('||i||').remarks          : '||p_audit.forms(i).remarks);

                -- Nested errors in the form
                if p_audit.forms(i).error.count > 0 
                then
                    for j in 1 .. p_audit.forms(i).error.count 
                    loop
                        dbms_output.put_line('  ↳ error('||j||').element_type_id            : '||p_audit.forms(i).error(j).element_type_id);
                        dbms_output.put_line('  ↳ error('||j||').error_type_id              : '||p_audit.forms(i).error(j).error_type_id);
                        dbms_output.put_line('  ↳ error('||j||').log_book_remark            : '||p_audit.forms(i).error(j).log_book_remark);
                        dbms_output.put_line('  ↳ error('||j||').log_book_image_id          : '||p_audit.forms(i).error(j).log_book_image_id);
                        dbms_output.put_line('  ↳ error('||j||').technical_aspects_remark   : '||p_audit.forms(i).error(j).technical_aspects_remark);
                        dbms_output.put_line('  ↳ error('||j||').technical_aspects_image_id : '||p_audit.forms(i).error(j).technical_aspects_image_id);
                        dbms_output.put_line('  ↳ error('||j||').error_count                : '||p_audit.forms(i).error(j).error_count);
                    end loop;
                else
                    dbms_output.put_line('  ↳ errors            : []');
                end if;

            end loop;
        else
            dbms_output.put_line('p_audit.forms            : []');
        end if;
        --   
    end p_dbms_output_record;
    --
    -----------------------------------------------------------------------------------------
    --  
    procedure p_update_audit(   p_adt_id                in number 
                            ,   p_signature_image_id    in number 
                            )
    is
    begin
        --
        update  icca_audits
        set     audit_completed     = 'Y'
        ,       signature_image_id  = p_signature_image_id
        where   id = p_adt_id
        ;
        --
    end p_update_audit;
    --
    -----------------------------------------------------------------------------------------
    --   
    procedure p_create_audit_present_clients(   p_adt_id            in number 
                                            ,   p_present_clients   in tt_present_clients
                                            )
    is
    begin
        --
        for i in 1..p_present_clients.count
        loop
            --
            merge into icca_adt_present_clients dest
                using ( select  p_adt_id                    as adt_id
                        ,       p_present_clients(i).name   as name
                    ) src
                on (    dest.adt_id      = src.adt_id
                    and upper(dest.name) = upper(src.name)
                    )
            when not matched 
                then insert ( dest.adt_id, dest.name )
                    values ( src.adt_id, src.name )
            ;
            --
        end loop;
        --
    end p_create_audit_present_clients;    
    --
    -----------------------------------------------------------------------------------------
    --      
    procedure p_update_audit_kpi_elements( p_kpi_elements in tt_kpi_elements )
    is
    begin
        --
        for i in 1..p_kpi_elements.count
        loop
            merge into icca_adt_kpi_elements dest
                using ( select  p_kpi_elements(i).audit_id          as adt_id
                        ,       (   select  id 
                                    from    icca_ket_clients 
                                    where   ket_id = p_kpi_elements(i).id 
                                    and     cnt_id = ( select cnt_id from icca_audits where id = p_kpi_elements(i).audit_id )
                                )                                   as kcn_id
                        ,       p_kpi_elements(i).id                as ket_id
                        ,       p_kpi_elements(i).elementLabel      as element_label
                        ,       p_kpi_elements(i).elementValue      as element_value
                        ,       p_kpi_elements(i).elementComment    as element_comment
                        from    dual
                    ) src
                on (    src.adt_id = dest.adt_id
                    and src.kcn_id = dest.kcn_id
                    and src.ket_id = dest.ket_id
                    )
            when not matched 
                then insert ( dest.kcn_id, dest.adt_id, dest.ket_id, dest.element_label, dest.element_value, dest.element_comment )
                        values ( src.kcn_id, src.adt_id, src.ket_id, src.element_label, src.element_value, src.element_comment )
            when matched
                then update set dest.element_label   = src.element_label
                            ,   dest.element_value   = src.element_value
                            ,   dest.element_comment = src.element_comment
            ;
        end loop;
        --
    end p_update_audit_kpi_elements;
    --
    -----------------------------------------------------------------------------------------
    --
    procedure p_create_audit_forms(     p_adt_id in number
                                    ,   p_forms  in tt_forms
                                    )
    is
        -- cursors
        cursor c_get_fom_row(   b_adt_id      in number
                            ,   b_flr_id      in number
                            ,   b_cat_id      in number
                            ,   b_ara_code    in varchar2
                            )
        is
            select  fom.*
            from    icca_adt_forms fom
            where   fom.adt_id      = b_adt_id
            and     fom.flr_id      = b_flr_id
            and     fom.cat_id      = b_cat_id
            and     fom.ara_id      = ( select id from icca_areas where abbreviation = regexp_substr(b_ara_code, '^[^\.]+') )
            and     fom.area_number = regexp_substr(b_ara_code, '[^.]+$', 1)
            ;
        --
        -- variables
        lr_fom icca_adt_forms%rowtype;
    begin
        --
        for i in 1..p_forms.count
        loop
            --
            -- merge form record
            merge into icca_adt_forms dest
                using ( select  p_adt_id                                                                        as adt_id
                        ,       p_forms(i).floor_id                                                             as flr_id
                        ,       p_forms(i).category_id                                                          as cat_id
                        ,       (   select  id 
                                    from    icca_areas 
                                    where   abbreviation = regexp_substr(p_forms(i).area_code, '^[^\.]+') )     as ara_id
                        ,       regexp_substr(p_forms(i).area_code, '[^.]+$', 1)                                as area_number                                
                        ,       p_forms(i).counter_elements                                                     as element_count
                        ,       p_forms(i).form_date                                                            as form_date
                        ,       p_forms(i).remarks                                                              as remark
                        from    dual
                    ) src
                on  (   src.adt_id      = dest.adt_id
                    and src.flr_id      = dest.flr_id
                    and src.cat_id      = dest.cat_id
                    and src.ara_id      = dest.ara_id
                    and src.area_number = dest.area_number
                    ) 
            when not matched 
                then insert (dest.adt_id, dest.flr_id, dest.cat_id, dest.ara_id, dest.element_count, dest.area_number, dest.remark)
                    values (src.adt_id, src.flr_id, src.cat_id, src.ara_id, src.element_count, src.area_number, src.remark)
            when matched
                then update set dest.element_count  = src.element_count
                            ,   dest.remark         = src.remark
            ;
            --
            -- haal net inserted fom row op
            open    c_get_fom_row(  b_adt_id    => p_adt_id
                                ,   b_flr_id    => p_forms(i).floor_id
                                ,   b_cat_id    => p_forms(i).category_id
                                ,   b_ara_code  => p_forms(i).area_code
                                );
            fetch   c_get_fom_row
            into    lr_fom;
            close   c_get_fom_row;                                
            --
            -- merge error voor deze form
            for y in 1..p_forms(i).error.count
            loop
                --
                merge into icca_fom_errors dest
                    using(  select  lr_fom.id                                       as fom_id
                            ,       p_forms(i).error(y).error_type_id               as ete_id
                            ,       p_forms(i).error(y).element_type_id             as epe_id
                            ,       p_forms(i).error(y).error_count                 as error_count
                            ,       p_forms(i).error(y).log_book_remark             as log_book_remark
                            ,       p_forms(i).error(y).log_book_image_id           as log_book_image_id
                            ,       p_forms(i).error(y).technical_aspects_remark    as technical_aspects_remark
                            ,       p_forms(i).error(y).technical_aspects_image_id  as technical_aspects_image_id
                            from    dual
                    ) src
                    on (    dest.fom_id = src.fom_id
                        and dest.ete_id = src.ete_id
                        and dest.epe_id = src.epe_id
                        )
                when not matched 
                    then insert ( dest.fom_id, dest.ete_id, dest.epe_id, dest.error_count, dest.log_book_remark, dest.log_book_image_id, dest.technical_aspects_remark, dest.technical_aspects_image_id )
                        values ( src.fom_id, src.ete_id, src.epe_id, src.error_count, src.log_book_remark, src.log_book_image_id, src.technical_aspects_remark, src.technical_aspects_image_id)
                when matched
                    then update set dest.error_count                = src.error_count
                                ,   dest.log_book_remark            = src.log_book_remark
                                ,   dest.technical_aspects_remark   = src.technical_aspects_remark
                                ,   dest.log_book_image_id          = src.log_book_image_id
                                ,   dest.technical_aspects_image_id = src.technical_aspects_image_id
                ;
                --
            end loop;
            --
        end loop;
        --
    end p_create_audit_forms;
    --
    -----------------------------------------------------------------------------------------
    --  process de ingekomen audit gegevens    
    procedure p_process_audit( p_audit in t_audit )
    is
        -- variables
        ln_adt_id number;
    begin
        --
        p_dbms_output_record( p_audit );
        --
        ln_adt_id := p_audit.id;
        --
        -- update audit to completed
        p_update_audit( p_adt_id => ln_adt_id , p_signature_image_id => p_audit.signature_image_id );
        -- --
        -- insert clients die aanwezig waren tijden de audit 
        p_create_audit_present_clients( p_adt_id            => ln_adt_id
                                    ,   p_present_clients   => p_audit.present_clients
                                    );
        --
        -- update KPI elementen voor deze audit
        p_update_audit_kpi_elements( p_kpi_elements => p_audit.kpi_elements );
        --
        -- maak audit formulieren aan met bijhorende fouten
        p_create_audit_forms(   p_adt_id => ln_adt_id
                            ,   p_forms  => p_audit.forms
                            );
        --
    end p_process_audit;
    --
    -----------------------------------------------------------------------------------------
    --  message handler voor ingekomen audit gegevens
    procedure p_msg_handler( p_incomming_message_id in number )
    is
        -- variables
        lr_ige              icca_incoming_messages%rowtype;
        l_audit             t_audit;
        l_audit_json_obj    json_object_t;
    begin
        --
        -- haal de record op die verwerkt moet worden
        lr_ige              := icca_incoming_msg.f_get_ige_row( p_incomming_message_id );
        --
        -- convert hem van string naar een json object
        l_audit_json_obj    := json_object_t.parse( lr_ige.message );
        --
        -- convert het json object naar plsql types
        l_audit             := f_audit_values( l_audit_json_obj );
        --
        -- process de ingekomen gegevens
        p_process_audit( l_audit );
        --
    end p_msg_handler;
    --
    -----------------------------------------------------------------------------------------
    --  
end icca_audit_post_api;
/