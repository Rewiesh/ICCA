create or replace package body icca_error_handeling 
is
    --
    gc_package constant varchar2(31) := $$plsql_unit || '.'; 
    --
    -----------------------------------------------------------------------------------------
    --
    function f_error_handling(p_error in apex_error.t_error)
    return apex_error.t_error_result 
    is
        --
        l_scope                 constant varchar2(61) := gc_package||'f_error_handling';
        l_params                logger.tab_param;
        --
        l_result                apex_error.t_error_result := null;
        l_constraint_name       varchar2(255) := null;
        lv_init_error_result    varchar2(2000) := null;
        ln_log_id               number := null;
        l_scherm_result         apex_error.t_error := null;
        lv_label                varchar2(300);
        lv_stap                 varchar2(3000); 
        --
        --private local function die de generieke foutmelding geeft
        function lf_generieke_foutmelding(pi_ora_code in varchar2)
        return varchar2 
        is
            --
            lv_gen_melding varchar2(1000);
            --
        begin
            --
            logger.log_error( p_text => 'Onverwachte fout opgetreden in APEX');
            --
            lv_gen_melding := 'Onverwachte fout opgetreden. Neem contact op met uw applicatiebeheerder en geef ' ||
                                'LOGGER_ID # ' || logger_logs_seq.currval || 
                                case when pi_ora_code is not null then ' en Oracle code ' ||pi_ora_code 
                                    else null
                                end|| ' mee voor verder onderzoek.'; 
            --                                      
            return lv_gen_melding;
            --
        end lf_generieke_foutmelding;
        --
    begin
        --
        l_scherm_result         := p_error;
        l_result                := apex_error.init_error_result(p_error => p_error);
        lv_init_error_result    := 'Message: ' || l_result.message ||' Additional info: ' ||l_result.additional_info;
        -- Hier worden voorgedefinieerde errors in packages opgevangen
        -- Bijvoorbeeld error code -20001 of -20002
        -- De foutmelding moet worden opgeslagen in het foutmeldingen tabel
        lv_stap := 'Evalueer de ora_sql_code ' || p_error.ora_sqlcode;
        --
        if p_error.ora_sqlcode <= -20000
        then
            --
            lv_stap := 'Error is een voorgedefinieerde error in een package. Haal de foutmelding op met naam = ' ||p_error.ora_sqlcode;
            --
            begin
                --
                select  message
                into    l_result.message
                from    icca_application_error_messages 
                where   upper(name) = upper(to_char(p_error.ora_sqlcode));
                --
            exception
            when no_data_found 
            then
                --
                lv_stap := 'Geen foutmelding record met naam = ' ||
                            p_error.ora_sqlcode ||
                            ' in gen_foutmelding. Sla de fout op in gen_log als package fout en geef een generieke foutmessage.';
                --
            end;
            --
        elsif p_error.ora_sqlcode in (-1, -2091, -2290, -2291, -2292)
        then
            --
            lv_stap := 'Error is een constraint violation met ora code ' || p_error.ora_sqlcode || '. Haal de constraint naam op.';
            --
            l_constraint_name := apex_error.extract_constraint_name(p_error => p_error);
            --
            begin
                --
                select  message
                into    l_result.message
                from    icca_application_error_messages 
                where   upper(name) = upper(l_constraint_name);
                --
            exception
            when no_data_found 
            then
                --
                lv_stap := 'Geen foutmelding record met naam = ' ||p_error.ora_sqlcode ||' in gen_foutmelding. Geef een generieke foutmelding.';
                --
                l_result.message := lf_generieke_foutmelding(p_error.ora_sqlcode);
                --
            end;
            --
        end if;
        --
        -- If it's an internal error raised by APEX, like an invalid statement or
        -- code which can't be executed, the error text might contain security sensitive
        -- information. To avoid this security problem we can rewrite the error to
        -- a generic error message and log the original error message for further
        -- investigation by the help desk.
        --
        if p_error.is_internal_error
        then
            --
            lv_stap := 'De error is een internal error. Ga na of het een autorisatie error is.';
            --
            if p_error.apex_error_code = 'APEX.AUTHORIZATION.ACCESS_DENIED'
            then
                --
                lv_stap                     := 'De error is een autorisatie error.';
                l_result.message            := 'U bent niet bevoegd tot deze pagina.';
                l_result.additional_info    := null;
                l_result.display_location   := apex_error.c_inline_in_notification;
                --
            elsif p_error.apex_error_code = 'APEX.PAGE.DUPLICATE_SUBMIT'
            then
                -- 
                l_result.message := 'U heeft al één keer gesubmit  en kunt niet nogmaals submitten.';
                --
            elsif p_error.apex_error_code <> 'APEX.AUTHORIZATION.ACCESS_DENIED'
            then
                --
                if p_error.ora_sqlcode = '-01858' or p_error.ora_sqlcode = '-1858'
                or p_error.ora_sqlcode = '-01861' or p_error.ora_sqlcode = '-1861'
                then
                    --
                    l_result.message         := 'U heeft een of meerdere karakters ingevoerd in een nummer- of datumveld.';
                    l_result.additional_info := null;
                    --
                else
                    --
                    l_result.message := lf_generieke_foutmelding(dbms_utility.format_error_backtrace);
                end if;
                --
            end if;
            --
            if p_error.apex_error_code = 'APEX.SESSION.EXPIRED'
            then
                --
                l_result.message          := 'Uw sessie is verlopen.';
                l_result.additional_info  := null;
                l_result.display_location := apex_error.c_inline_in_notification;
                --
            end if;
            --  
        elsif   p_error.ora_sqlcode = '-06502' or p_error.ora_sqlcode = '-6502'
            or  p_error.ora_sqlcode = '-01722' or p_error.ora_sqlcode = '-1722'
        then
            --
            l_result.message         := 'U heeft een of meerdere karakters ingevoerd in een nummer- of datumveld.';
            l_result.additional_info := null;
            lv_stap                  := 'Sla de internal conversie error ook op in gen_log tabel';
            --
        elsif p_error.ora_sqlcode = '-12899'
        then
            --
            l_result.message := 'U hebt meer karakters ingevuld dan toegestaan. Neem contact op met uw applicatiebeheerder voor meer informatie.';
            --
        elsif p_error.ora_sqlcode in (-04063, -06508)
        then
            --
            l_result.message := lf_generieke_foutmelding(p_error.ora_sqlcode);
            --
        elsif p_error.ora_sqlcode = '-01438'
        then
            --
            l_result.message := 'U hebt meer cijfers achter de komma ingevuld dan toegestaan. Neem contact op met uw applicatiebeheerder voor meer informatie.';
            --
        else
            -- If no associated page item/tabular form column has been set, we can use
            -- apex_error.auto_set_associated_item to automatically guess the affected
            -- error field by examine the ORA error for constraint names or column names.
            if  l_result.page_item_name is null
            and l_result.column_alias is null
            then
                --
                apex_error.auto_set_associated_item(p_error        => p_error,
                                                    p_error_result => l_result);
                l_result.display_location := apex_error.c_inline_in_notification;
                --
            elsif l_result.page_item_name is not null
            then
                select  apxpgitm.label
                into    lv_label
                from    apex_application_page_items apxpgitm
                where   apxpgitm.item_name = l_scherm_result.page_item_name
                and     apxpgitm.application_id = nv('APP_ID');
                --
            end if;
            --
        end if;
        --
        return l_result;
        --
    exception
    when others 
    then
        rollback;
        raise;
    end f_error_handling;
    --
    -----------------------------------------------------------------------------------------
    --
end icca_error_handeling;
/