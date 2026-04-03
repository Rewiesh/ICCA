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
    --  convert: FORMS Remarks Json Object
    function f_get_form_remarks(p_remarks_json_arr in json_array_t)
    return tt_remarks
    is
        -- variables
        lr_remarks      tt_remarks;
        l_remark_obj    json_object_t;
        l_count         pls_integer;
    begin
        --
        if p_remarks_json_arr is null 
        then
            --
            return lr_remarks;
            --
        end if;
        --
        l_count := p_remarks_json_arr.get_size;
        --
        for i in 0 .. l_count - 1 
        loop
            --
            l_remark_obj := treat( p_remarks_json_arr.get(i) as json_object_t );
            --
            lr_remarks(i + 1).remark_text     := l_remark_obj.get_string('RemarkText');
            lr_remarks(i + 1).remark_image_id := l_remark_obj.get_number('RemarkImageId');
            --
        end loop;
        --
        return lr_remarks;
        --
    end f_get_form_remarks;
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
            
            -- Nested remarks array
            lr_forms(i + 1).remark := f_get_form_remarks(l_form_obj.get_array('RemarksList'));
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

                -- Nested remarks in the form
                if p_audit.forms(i).remark.count > 0 
                then
                    for k in 1 .. p_audit.forms(i).remark.count 
                    loop
                        dbms_output.put_line('  ↳ remark('||k||').remark_text    : '||p_audit.forms(i).remark(k).remark_text);
                        dbms_output.put_line('  ↳ remark('||k||').remark_image_id: '||p_audit.forms(i).remark(k).remark_image_id);
                    end loop;
                else
                    dbms_output.put_line('  ↳ remarks           : []');
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
    procedure p_update_audit(   p_pfr_id                in number   
                            ,   p_adt_id                in number 
                            ,   p_signature_image_id    in number 
                            ,   p_last_control_date     in date
                            )
    is
    begin
        --
        update  icca_audits
        set     pfr_id              = p_pfr_id
        ,       audit_completed     = 'Y'
        ,       signature_image_id  = p_signature_image_id
        ,       last_control_date   = p_last_control_date
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
    procedure p_create_form_remarks(   p_fom_id    in number
                                   ,   p_remarks   in tt_remarks
                                   )
    is
    begin
        --
        -- verwijder bestaande remarks voor deze form
        delete from icca_form_remarks
        where fom_id = p_fom_id;
        --
        -- insert nieuwe remarks
        for i in 1..p_remarks.count
        loop
            insert into icca_form_remarks (
                fom_id
            ,   remark_text
            ,   remark_image_id
            )
            values (
                p_fom_id
            ,   p_remarks(i).remark_text
            ,   p_remarks(i).remark_image_id
            );
        end loop;
        --
    end p_create_form_remarks;
    --
    -----------------------------------------------------------------------------------------
    --
    procedure p_create_audit_forms(     p_adt_id in number
                                    ,   p_pfr_id in number 
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
        lr_fom                  icca_adt_forms%rowtype;
        ln_fom_tot_error_count  number := 0;
    begin
        --
        for i in 1..p_forms.count
        loop
            --
            -- merge form record
            merge into icca_adt_forms dest
                using ( select  p_adt_id                                                                        as adt_id
                        ,       p_pfr_id                                                                        as pfr_id
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
                then insert (dest.adt_id, dest.pfr_id, dest.flr_id, dest.cat_id, dest.ara_id, dest.element_count, dest.area_number, dest.remark)
                    values (src.adt_id, src.pfr_id, src.flr_id, src.cat_id, src.ara_id, src.element_count, src.area_number, src.remark)
            when matched
                then update set dest.pfr_id         = src.pfr_id
                            ,   dest.element_count  = src.element_count
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
                -- validatie: element_type_id en error_type_id mogen niet leeg zijn
                if p_forms(i).error(y).element_type_id is null 
                    or p_forms(i).error(y).error_type_id is null 
                then
                    declare
                        lv_element_name varchar2(100);
                        lv_error_name   varchar2(100);
                        lv_error_msg    varchar2(4000);
                    begin
                        -- haal element type naam op
                        if p_forms(i).error(y).element_type_id is not null then
                            begin
                                select name into lv_element_name
                                from icca_elementtypes
                                where id = p_forms(i).error(y).element_type_id;
                            exception
                                when no_data_found then
                                    lv_element_name := 'Onbekend (ID: ' || p_forms(i).error(y).element_type_id || ')';
                            end;
                        else
                            lv_element_name := 'NIET INGEVULD';
                        end if;
                        
                        -- haal error type naam op
                        if p_forms(i).error(y).error_type_id is not null then
                            begin
                                select name into lv_error_name
                                from icca_error_types
                                where id = p_forms(i).error(y).error_type_id;
                            exception
                                when no_data_found then
                                    lv_error_name := 'Onbekend (ID: ' || p_forms(i).error(y).error_type_id || ')';
                            end;
                        else
                            lv_error_name := 'NIET INGEVULD';
                        end if;
                        
                        -- bouw gebruiksvriendelijke error message
                        lv_error_msg := 'Fout bij formulier ' || p_forms(i).area_code || ': ' ||
                                       'Fout #' || y || ' kan niet worden opgeslagen. ' ||
                                       'Element: "' || lv_element_name || '", ' ||
                                       'Soort fout: "' || lv_error_name || '". ' ||
                                       'Beide velden zijn verplicht om een fout op te slaan.';
                        
                        raise_application_error(-20001, lv_error_msg);
                    end;
                end if;
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
                -- tel de errors op
                ln_fom_tot_error_count := ln_fom_tot_error_count + p_forms(i).error(y).error_count;
            end loop;
            --
            -- opslaan van opmerkingen voor deze form (indien aanwezig)
            if p_forms(i).remark.count > 0 then
                p_create_form_remarks(
                    p_fom_id    => lr_fom.id
                ,   p_remarks   => p_forms(i).remark
                );
            end if;
            --
            -- update de form met het totaal aantal errors
            update  icca_adt_forms
            set     error_count = ln_fom_tot_error_count
            where   id = lr_fom.id
            ;
            -- reset de error count voor de volgende form
            ln_fom_tot_error_count := 0;
        end loop;
        --
    end p_create_audit_forms;
    --
    -----------------------------------------------------------------------------------------
    --  bereken de audit resultaten
    procedure p_calculate_audit_results( p_adt_id in number )
    is
        -- cursors
        cursor c_get_audit_results( b_adt_id in number )
        is
            select  fom.adt_id              as adt_id
            ,       fom.cat_id              as cat_id
            ,       sum(fom.element_count)  as counter_elements
            ,       sum(fom.error_count)    as counter_errors
            from    icca_adt_forms fom
            where   fom.adt_id = b_adt_id
            group by adt_id
                   , cat_id
            ;
        --
        cursor c_get_category_limits(   b_cat_id            in number
                                    ,   b_counter_elements  in number
                                    )
        is
            select  clm.approve_limit   as cat_approve_limit
            ,       clm.min_size_range  as cat_min_size_range
            from    icca_categories               cat
            join    icca_cat_limits               clm on clm.cat_id = cat.id
            join    icca_cat_buildingsize_scales  cbe on clm.cbe_id = cbe.id
            where   cat_id = b_cat_id
            and     b_counter_elements between cbe.min_val and cbe.max_val
            fetch first 1 rows only
            ;
        --
        cursor c_get_audit_score( b_audit_ratio in number )
        is
            select  score
            from    (
                        select  score
                        ,       fault_perc
                        from    icca_scores
                        where   fault_perc <= b_audit_ratio
                        order by fault_perc desc
                    )
            where rownum = 1;
        --
        -- variables
        type t_audit_results is table of c_get_audit_results%rowtype index by pls_integer;
        lt_audit_results            t_audit_results;
        ln_cat_approve_limit        number := 0;
        ln_cat_min_size_range       number := 0;
        ln_approve_limit            number := 0;
        ln_audit_score_ratio        number := 0;
        ln_audit_score              number := 0;
        ln_default_approve_limit    number := 6; -- default goedkeurings limiet
    begin
        --
        -- haal de audit resultaten op
        open    c_get_audit_results( b_adt_id => p_adt_id );
        fetch   c_get_audit_results
        bulk collect into lt_audit_results;
        close   c_get_audit_results;
        --
        -- loop door de resultaten heen
        for i in 1 .. lt_audit_results.count
        loop
            --
            -- haal de categorie goedkeurings limiet op
            open    c_get_category_limits(  b_cat_id            => lt_audit_results(i).cat_id
                                        ,   b_counter_elements  => lt_audit_results(i).counter_elements
                                        );
            fetch   c_get_category_limits
            into    ln_cat_approve_limit, ln_cat_min_size_range;
            close   c_get_category_limits;
            --                                        
            -- bepaal de goedkeurings limiet
            -- ( ln_cat_approve_limit / ln_cat_min_size_range ) * lt_audit_results(i).counter_elements
            ln_approve_limit        := ceil(( ln_cat_approve_limit 
                                                / case 
                                                    when ln_cat_min_size_range > 0 then ln_cat_min_size_range
                                                    else 1
                                                  end  
                                            ) * lt_audit_results(i).counter_elements
                                        );
            --
            -- Bepaal de audit score
            if lt_audit_results(i).counter_errors = 0 then
                -- Geen fouten: maximale score
                ln_audit_score := 10;
            else
                -- Ratio van fouten tot elementen
                ln_audit_score_ratio := ( ln_approve_limit 
                                          / lt_audit_results(i).counter_errors
                                        ) * 100;
                --
                -- get de audit score op basis van de ratio
                open    c_get_audit_score( b_audit_ratio => ln_audit_score_ratio );
                fetch   c_get_audit_score 
                into    ln_audit_score;
                close   c_get_audit_score;
            end if;
            --
            -- insert de resultaten in de audit resultaten tabel
            merge into icca_adt_results dest
                using ( select  lt_audit_results(i).adt_id                                                  as adt_id
                        ,       lt_audit_results(i).cat_id                                                  as cat_id
                        ,       ln_approve_limit                                                            as approve_limit
                        ,       lt_audit_results(i).counter_elements                                        as counter_elements
                        ,       lt_audit_results(i).counter_errors                                          as counter_errors
                        ,       ln_audit_score                                                              as score
                        ,       case when ln_audit_score >= ln_default_approve_limit then 'Y' else 'N' end  as is_sufficient
                        from    dual
                    ) src
                on (    dest.adt_id = src.adt_id
                    and dest.cat_id = src.cat_id
                    )
            when not matched
                then insert ( dest.adt_id, dest.cat_id, dest.approve_limit, dest.counter_elements, dest.counter_errors, dest.score, dest.is_sufficient )
                        values ( src.adt_id, src.cat_id, src.approve_limit, src.counter_elements, src.counter_errors, src.score, src.is_sufficient )
            when matched
                then update set dest.approve_limit     = src.approve_limit
                            ,   dest.counter_elements  = src.counter_elements
                            ,   dest.counter_errors    = src.counter_errors
                            ,   dest.score             = src.score
                            ,   dest.is_sufficient     = src.is_sufficient
            ;
            --
        end loop;
        --
    end p_calculate_audit_results;
    --
    -----------------------------------------------------------------------------------------
    --  process de ingekomen audit gegevens    
    procedure p_process_audit(  p_pfr_id in number
                            ,   p_audit  in t_audit )
    is
        -- variables
        ln_adt_id number;
    begin
        --
        p_dbms_output_record( p_audit );
        --
        ln_adt_id := p_audit.id;
        --
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
                            ,   p_pfr_id => p_pfr_id
                            ,   p_forms  => p_audit.forms
                            );
        --
        -- bereken de audit resultaten
        p_calculate_audit_results( p_adt_id => ln_adt_id );
        --
        -- update audit to completed
        p_update_audit( p_pfr_id => p_pfr_id, p_adt_id => ln_adt_id , p_signature_image_id => p_audit.signature_image_id, p_last_control_date => p_audit.audit_date );
        --
        --
    end p_process_audit;
    --
    --
    -----------------------------------------------------------------------------------------
    --
    function f_array_to_string(
        p_array in sys.odcivarchar2list,
        p_separator in varchar2 default ','
    ) return varchar2
    is
        l_result varchar2(4000);
    begin
        if p_array is null or p_array.count = 0 then
            return null;
        end if;

        for i in 1 .. p_array.count loop
            if i = 1 then
                l_result := p_array(i);
            else
                l_result := l_result || p_separator || p_array(i);
            end if;
        end loop;

        return l_result;
    end f_array_to_string;  
    --
    --
    -----------------------------------------------------------------------------------------
    -- Mail sturen naar de klant
    procedure p_send_audit_mail( p_adt_id in number )
    is
        -- cursors
        cursor c_get_audit_data( b_adt_id in number )
        is
            select  adt.id
            ,       adt.code
            ,       adt.audit_date
            ,       adt.cnt_id
            ,       cnt.company_name
            ,       cnt.contact_person       as cnt_contact_person
            ,       cnt.usr_id
            ,       cln.id                   as cln_id
            ,       cln.name                 as location_name
            ,       cln.contact_person       as cln_contact_person
            ,       cln.email                as cln_email
            ,       cnt.send_reports_to_default_email
            ,       listagg(ueml.email, ',') within group (order by ueml.created_date desc) as usr_emails
            from    icca_audits             adt
            join    icca_clients            cnt on cnt.id = adt.cnt_id
            join    icca_client_locations   cln on cln.id = adt.cln_id
            left join icca_usr_emails       ueml on ueml.usr_id = cnt.usr_id
            where   adt.id = b_adt_id
            group by adt.id, adt.code, adt.audit_date, adt.cnt_id, 
                    cnt.company_name, cnt.contact_person, cnt.usr_id,
                    cln.id, cln.name, cln.contact_person, cln.email,
                    cnt.send_reports_to_default_email
            ;

        -- constants
        gc_icca_email constant varchar2(100) := 'info@iccaadvies.eu';
        -- gc_icca_email constant varchar2(100) := 'ramcharanrewiesh98@hotmail.com';

        -- variables
        lr_audit_data       c_get_audit_data%rowtype;
        l_email_addresses   varchar2(4000);
        l_temp_emails       sys.odcivarchar2list := sys.odcivarchar2list();
        l_forms_count       number := 0;
    begin
        --
        -- Check 1: Bestaat de audit?
        open    c_get_audit_data( b_adt_id => p_adt_id );
        fetch   c_get_audit_data into lr_audit_data;

        if c_get_audit_data%notfound then
            close c_get_audit_data;
            logger.log_warning(
                p_text  => 'Audit niet gevonden voor mail verzending',
                p_scope => 'icca_audit_post_api.p_send_audit_mail',
                p_extra => 'ADT_ID=' || p_adt_id
            );
            return;  -- Stop, maar geen error
        end if;

        close c_get_audit_data;

        --
        -- Check 2: Zijn er forms voor deze audit?
        begin
            select  count(*)
            into    l_forms_count
            from    icca_adt_forms
            where   adt_id = p_adt_id
            ;
        exception
            when no_data_found then
                l_forms_count := 0;
        end;

        if l_forms_count = 0 then
            logger.log_info(
                p_text  => 'Geen forms gevonden voor audit - mail verzending overgeslagen',
                p_scope => 'icca_audit_post_api.p_send_audit_mail',
                p_extra => 'ADT_ID=' || p_adt_id || 
                        ', CODE=' || lr_audit_data.code
            );
            return;  -- Stop, maar geen error
        end if;

        logger.log_info(
            p_text  => 'Forms check geslaagd',
            p_scope => 'icca_audit_post_api.p_send_audit_mail',
            p_extra => 'ADT_ID=' || p_adt_id || 
                    ', FORMS_COUNT=' || l_forms_count
        );

        --
        -- Verzamel ontvangers
        -- 1. Locatie emails (kan meerdere zijn, comma-separated)
        if lr_audit_data.cln_email is not null then
            -- Split de comma-separated cln_emails en voeg elk toe
            for rec in (
                select distinct trim(regexp_substr(lr_audit_data.cln_email, '[^,]+', 1, level)) as email
                from   dual
                connect by level <= regexp_count(lr_audit_data.cln_email, ',') + 1
            ) loop
                if rec.email is not null then
                    l_temp_emails.extend;
                    l_temp_emails(l_temp_emails.count) := rec.email;
                end if;
            end loop;
        end if;

        -- 2. User emails (kan meerdere zijn, comma-separated)
        if lr_audit_data.usr_emails is not null then
            -- Split de comma-separated usr_emails en voeg elk toe
            for rec in (
                select distinct trim(regexp_substr(lr_audit_data.usr_emails, '[^,]+', 1, level)) as email
                from   dual
                connect by level <= regexp_count(lr_audit_data.usr_emails, ',') + 1
            ) loop
                if rec.email is not null then
                    -- Check of email al bestaat in l_temp_emails
                    declare
                        l_email_exists boolean := false;
                    begin
                        for i in 1 .. l_temp_emails.count loop
                            if l_temp_emails(i) = rec.email then
                                l_email_exists := true;
                                exit;
                            end if;
                        end loop;
                        
                        -- Voeg alleen toe als nog niet aanwezig
                        if not l_email_exists then
                            l_temp_emails.extend;
                            l_temp_emails(l_temp_emails.count) := rec.email;
                        end if;
                    end;
                end if;
            end loop;
        end if;

        -- 3. ICCA email alleen als extra ontvanger wanneer dit voor de klant is ingeschakeld
        if lr_audit_data.send_reports_to_default_email = 'Y' then
            l_temp_emails.extend;
            l_temp_emails(l_temp_emails.count) := gc_icca_email;
        end if;

        -- Converteer array naar comma-separated string
        l_email_addresses := f_array_to_string(l_temp_emails);

        -- Log welke emails verstuurd worden
        logger.log_info(
            p_text  => 'Start audit mail verzending via API',
            p_scope => 'icca_audit_post_api.p_send_audit_mail',
            p_extra => 'ADT_ID=' || p_adt_id || 
                    ', CODE=' || lr_audit_data.code ||
                    ', EMAILS=' || l_email_addresses ||
                    ', EMAIL_COUNT=' || l_temp_emails.count ||
                    ', FORMS_COUNT=' || l_forms_count
        );

        -- Roep de centrale audit mail procedure aan
        icca_audit_mail.p_send_audit_report(
            p_adt_id          => p_adt_id,
            p_email_addresses => l_email_addresses
        );

        -- Log success
        logger.log_info(
            p_text  => 'Audit mail via API succesvol afgerond',
            p_scope => 'icca_audit_post_api.p_send_audit_mail',
            p_extra => 'ADT_ID=' || p_adt_id
        );

    exception
        when others then
            logger.log_error(
                p_text  => 'Fout bij versturen audit mail via API',
                p_scope => 'icca_audit_post_api.p_send_audit_mail',
                p_extra => 'ADT_ID=' || p_adt_id || 
                        ', ERROR=' || sqlerrm ||
                        ', BACKTRACE=' || dbms_utility.format_error_backtrace
            );
            -- raise; -- bewust uit: mail fouten mogen API processing niet blokkeren
    end p_send_audit_mail;
    --
    -----------------------------------------------------------------------------------------
    --  message handler voor ingekomen audit gegevens
    procedure p_msg_handler( p_incomming_message_id in number, po_audit_id out number )
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
        p_process_audit( lr_ige.pfr_id, l_audit );
        --
        -- stuur de audit rapport naar de klant
        p_send_audit_mail( l_audit.id );
        --
        po_audit_id := l_audit.id;
        --
    end p_msg_handler;
    --
    -----------------------------------------------------------------------------------------
    --  
end icca_audit_post_api;
/