create or replace package body icca_dashboard_api_pkg
as
    /*
        Package Body: icca_dashboard_api_pkg
        Purpose: Implementatie van dashboard API functionaliteit
        
        Dependencies:
        - icca_api_dashboard_vw: View met audit resultaten
        
        Security:
        - Data filtering gebeurt in de view (cnt.send_data_to_dashboard = 'Y')
        
        Performance:
        - Chunked output voor grote datasets (100k+ rows)
    */
    
    /*
        Start: Helper functions
    */
    --
    -----------------------------------------------------------------------------------------
    --  GET TOTAL COUNT
    function f_get_total_count(
        p_audit_code    in varchar2,
        p_company_name  in varchar2,
        p_jaar          in number,
        p_maand         in number
    )
    return number
    is
        --
        -- variables
        ln_total_count number := 0;
    begin
        --
        select  count(*)
        into    ln_total_count
        from    icca_api_dashboard_vw
        where   (p_audit_code is null or auditcode = p_audit_code)
        and     (p_company_name is null or upper(companyname) = upper(p_company_name))
        and     (p_jaar is null or jaar = p_jaar)
        and     (p_maand is null or extract(month from audituitgevoerddatum) = p_maand);
        --
        return ln_total_count;
        --
    exception
        when others then
            return 0;
    end f_get_total_count;
    --
    -----------------------------------------------------------------------------------------
    --
    /*
        Start: Fill types functions
    */
    --
    -----------------------------------------------------------------------------------------
    --  AUDIT RESULTS TYPE
    function f_audit_results_tab(
        p_audit_code    in varchar2 default null,
        p_company_name  in varchar2 default null,
        p_jaar          in number   default null,
        p_maand         in number   default null,
        p_page          in number   default 1,
        p_page_size     in number   default 1000
    )
    return tt_audit_results
    is  
        --
        -- cursors
        cursor c_get_audit_results(
            b_audit_code    in varchar2,
            b_company_name  in varchar2,
            b_jaar          in number,
            b_maand         in number,
            b_offset        in number,
            b_fetch_rows    in number
        )
        is
            select  companyid           as company_id
            ,       auditid             as audit_id
            ,       fomid               as fom_id
            ,       companyname         as company_name
            ,       name                as name
            ,       region              as region
            ,       to_char(audituitgevoerddatum, 'YYYY-MM-DD') as audit_date
            ,       auditcode           as audit_code
            ,       categoryname        as category_name
            ,       areacode            as area_code
            ,       gkgrens             as gk_grens
            ,       resultaat           as resultaat
            ,       elementtypevalue    as element_type_value
            ,       errortypevalue      as error_type_value
            ,       fout                as fout
            ,       jaar                as jaar
            ,       aantal_contr        as aantal_contr
            from    icca_api_dashboard_vw
            where   (b_audit_code is null or auditcode = b_audit_code)
            and     (b_company_name is null or upper(companyname) = upper(b_company_name))
            and     (b_jaar is null or jaar = b_jaar)
            and     (b_maand is null or extract(month from audituitgevoerddatum) = b_maand)
            order by auditcode, categoryname, areacode
            offset b_offset rows fetch next b_fetch_rows rows only
            ;
        -- 
        -- variables
        lt_audit_results        tt_audit_results;
        ln_audit_result_idx     pls_integer := 0;
        ln_offset               number;
    begin
        --
        -- calculate offset for pagination
        ln_offset := (nvl(p_page, 1) - 1) * nvl(p_page_size, 1000);
        --
        for r_audit_result in c_get_audit_results(
            p_audit_code, 
            p_company_name, 
            p_jaar, 
            p_maand, 
            ln_offset, 
            nvl(p_page_size, 1000)
        )
        loop
            --
            ln_audit_result_idx := ln_audit_result_idx + 1;
            lt_audit_results( ln_audit_result_idx ).company_id        := r_audit_result.company_id;
            lt_audit_results( ln_audit_result_idx ).audit_id          := r_audit_result.audit_id;
            lt_audit_results( ln_audit_result_idx ).fom_id            := r_audit_result.fom_id;
            lt_audit_results( ln_audit_result_idx ).company_name       := r_audit_result.company_name;
            lt_audit_results( ln_audit_result_idx ).name               := r_audit_result.name;
            lt_audit_results( ln_audit_result_idx ).region             := r_audit_result.region;
            lt_audit_results( ln_audit_result_idx ).date               := r_audit_result.audit_date;
            lt_audit_results( ln_audit_result_idx ).audit_code         := r_audit_result.audit_code;
            lt_audit_results( ln_audit_result_idx ).category_name      := r_audit_result.category_name;
            lt_audit_results( ln_audit_result_idx ).area_code          := r_audit_result.area_code;
            lt_audit_results( ln_audit_result_idx ).gk_grens           := r_audit_result.gk_grens;
            lt_audit_results( ln_audit_result_idx ).resultaat          := r_audit_result.resultaat;
            lt_audit_results( ln_audit_result_idx ).element_type_value := r_audit_result.element_type_value;
            lt_audit_results( ln_audit_result_idx ).error_type_value   := r_audit_result.error_type_value;
            lt_audit_results( ln_audit_result_idx ).fout               := r_audit_result.fout;
            lt_audit_results( ln_audit_result_idx ).jaar               := r_audit_result.jaar;
            lt_audit_results( ln_audit_result_idx ).aantal_contr       := r_audit_result.aantal_contr;
            --
        end loop;
        --
        return lt_audit_results;
        --
    end f_audit_results_tab;
    --
    -----------------------------------------------------------------------------------------
    --  OUTPUT TYPE
    function f_dashboard_api_rec(
        p_audit_code    in varchar2 default null,
        p_company_name  in varchar2 default null,
        p_jaar          in number   default null,
        p_maand         in number   default null,
        p_page          in number   default 1,
        p_page_size     in number   default 1000
    )
    return t_dashboard_api
    is
        -- 
        -- variables
        lr_dashboard_api_rec        t_dashboard_api;
        ln_validated_page_size      number;
        ln_total_count              number;
        ln_validated_page           number;
        -- constants
        c_default_page_size         constant number := 1000;
        c_max_page_size             constant number := 5000;
    begin
        --
        -- validate maand parameter (must be between 1 and 12, or null)
        if p_maand is not null and (p_maand < 1 or p_maand > 12) then
            -- invalid month, return empty result
            lr_dashboard_api_rec.audit_results  := tt_audit_results();
            lr_dashboard_api_rec.total_count    := 0;
            lr_dashboard_api_rec.page           := nvl(p_page, 1);
            lr_dashboard_api_rec.page_size      := nvl(p_page_size, c_default_page_size);
            lr_dashboard_api_rec.total_pages    := 0;
            return lr_dashboard_api_rec;
        end if;
        --
        -- validate and cap page_size (minimum 1, maximum 5000)
        ln_validated_page_size := least(greatest(nvl(p_page_size, c_default_page_size), 1), c_max_page_size);
        --
        -- validate page (minimum 1)
        ln_validated_page := greatest(nvl(p_page, 1), 1);
        --
        -- get total count with all filters
        ln_total_count := f_get_total_count(p_audit_code, p_company_name, p_jaar, p_maand);
        --
        -- get audit results with pagination and filters
        lr_dashboard_api_rec.audit_results := f_audit_results_tab(
            p_audit_code    => p_audit_code,
            p_company_name  => p_company_name,
            p_jaar          => p_jaar,
            p_maand         => p_maand,
            p_page          => ln_validated_page,
            p_page_size     => ln_validated_page_size
        );
        --
        -- set metadata
        lr_dashboard_api_rec.total_count    := ln_total_count;
        lr_dashboard_api_rec.page           := ln_validated_page;
        lr_dashboard_api_rec.page_size      := ln_validated_page_size;
        lr_dashboard_api_rec.total_pages    := case 
                                                    when ln_total_count > 0 
                                                    then ceil(ln_total_count / ln_validated_page_size) 
                                                    else 0 
                                                end;
        --
        return lr_dashboard_api_rec;
        --
    end f_dashboard_api_rec;
    --
    -----------------------------------------------------------------------------------------
    --
    /*
        End: Fill types functions
    */
    --
    -----------------------------------------------------------------------------------------
    --    
    /*
        Start: Create json objects
    */    
    --
    -----------------------------------------------------------------------------------------
    --  AUDIT RESULTS JSON     
    function f_audit_results_json_array_obj( p_audit_results_tab in tt_audit_results)
    return json_array_t
    is
        -- 
        -- variables    
        l_audit_results_json_array_obj json_array_t := json_array_t();
    begin
        --
        for i in 1..p_audit_results_tab.count
        loop
            declare
                l_one_audit_result_json_obj json_object_t := json_object_t();
            begin
                l_one_audit_result_json_obj.put( 'companyId'        , p_audit_results_tab(i).company_id );
                l_one_audit_result_json_obj.put( 'auditId'          , p_audit_results_tab(i).audit_id );
                l_one_audit_result_json_obj.put( 'fomId'            , p_audit_results_tab(i).fom_id );
                l_one_audit_result_json_obj.put( 'companyName'      , icca_json_util.f_sanitize_json_string( p_audit_results_tab(i).company_name ) );
                l_one_audit_result_json_obj.put( 'name'             , icca_json_util.f_sanitize_json_string( p_audit_results_tab(i).name ) );
                l_one_audit_result_json_obj.put( 'region'           , icca_json_util.f_sanitize_json_string( p_audit_results_tab(i).region ) );
                l_one_audit_result_json_obj.put( 'date'             , p_audit_results_tab(i).date );
                l_one_audit_result_json_obj.put( 'auditCode'        , icca_json_util.f_sanitize_json_string( p_audit_results_tab(i).audit_code ) );
                l_one_audit_result_json_obj.put( 'categoryName'     , icca_json_util.f_sanitize_json_string( p_audit_results_tab(i).category_name ) );
                l_one_audit_result_json_obj.put( 'areaCode'         , icca_json_util.f_sanitize_json_string( p_audit_results_tab(i).area_code ) );
                l_one_audit_result_json_obj.put( 'gkGrens'          , p_audit_results_tab(i).gk_grens );
                l_one_audit_result_json_obj.put( 'resultaat'        , p_audit_results_tab(i).resultaat );
                l_one_audit_result_json_obj.put( 'elementTypeValue' , icca_json_util.f_sanitize_json_string( p_audit_results_tab(i).element_type_value ) );
                l_one_audit_result_json_obj.put( 'errorTypeValue'   , icca_json_util.f_sanitize_json_string( p_audit_results_tab(i).error_type_value ) );
                l_one_audit_result_json_obj.put( 'fout'             , p_audit_results_tab(i).fout );
                l_one_audit_result_json_obj.put( 'jaar'             , p_audit_results_tab(i).jaar );
                l_one_audit_result_json_obj.put( 'aantalContr'      , p_audit_results_tab(i).aantal_contr );
                l_audit_results_json_array_obj.append( l_one_audit_result_json_obj );
            end;            
        end loop;
        --
        return l_audit_results_json_array_obj;
        --
    end f_audit_results_json_array_obj;
    --
    -----------------------------------------------------------------------------------------
    --  OUTPUT JSON
    function f_dashboard_api_json_obj( p_dashboard_api_rec in t_dashboard_api )
    return json_object_t
    is
        -- 
        -- variables
        lr_dashboard_api_type_to_json_obj json_object_t  :=  json_object_t();
        lr_pagination_json_obj            json_object_t  :=  json_object_t();
    begin
        -- build final json message
        --
        -- create pagination object
        lr_pagination_json_obj.put('page', p_dashboard_api_rec.page);
        lr_pagination_json_obj.put('pageSize', p_dashboard_api_rec.page_size);
        lr_pagination_json_obj.put('totalRecords', p_dashboard_api_rec.total_count);
        lr_pagination_json_obj.put('totalPages', p_dashboard_api_rec.total_pages);
        --
        -- add pagination to output
        lr_dashboard_api_type_to_json_obj.put('pagination', lr_pagination_json_obj);
        --
        -- add audit_results to output
        if p_dashboard_api_rec.audit_results.count > 0
        then
            lr_dashboard_api_type_to_json_obj.put('audit_results', f_audit_results_json_array_obj( p_dashboard_api_rec.audit_results ));
        else
            -- return empty array if no results
            lr_dashboard_api_type_to_json_obj.put('audit_results', json_array_t());
        end if;
        --          
        return lr_dashboard_api_type_to_json_obj;
        --
    end f_dashboard_api_json_obj;
    --
    -----------------------------------------------------------------------------------------
    --
    /*
        End: Create json objects
    */
    --
    -----------------------------------------------------------------------------------------
    --
    /*
        OUTPUT
    */
    --
    -----------------------------------------------------------------------------------------
    --       
    procedure p_get_data(
        p_audit_code    in varchar2 default null,
        p_company_name  in varchar2 default null,
        p_jaar          in number   default null,
        p_maand         in number   default null,
        p_page          in number   default 1,
        p_page_size     in number   default 1000
    )
    is
        -- variables
        lt_dashboard_api_json_obj   json_object_t;
        l_msg_clob                  clob;
        l_chunk_size                constant pls_integer := 32000;
        l_offset                    pls_integer := 1;
        l_total_length              pls_integer;
        l_params                    logger.tab_param;
        -- constants
        c_default_page_size         constant number := 1000;
        c_max_page_size             constant number := 5000;
        ln_validated_page_size      number;
    begin
        -- SET PROPER CONTENT TYPE
        owa_util.mime_header('application/json; charset=utf-8', false);
        owa_util.http_header_close;
        --
        -- validate page parameter (must be >= 1)
        if nvl(p_page, 1) < 1 then
            htp.prn('{"error":"Invalid page number. Must be >= 1"}');
            return;
        end if;
        --
        -- validate maand parameter (must be between 1 and 12, or null)
        if p_maand is not null and (p_maand < 1 or p_maand > 12) then
            htp.prn('{"error":"Invalid month. Must be between 1 and 12"}');
            return;
        end if;
        --
        -- validate and cap page_size (minimum 1, maximum 5000)
        ln_validated_page_size := least(greatest(nvl(p_page_size, c_default_page_size), 1), c_max_page_size);
        --
        -- convert data to json object
        lt_dashboard_api_json_obj := f_dashboard_api_json_obj( 
            f_dashboard_api_rec( 
                p_audit_code    => p_audit_code,
                p_company_name  => p_company_name,
                p_jaar          => p_jaar,
                p_maand         => p_maand,
                p_page          => p_page,
                p_page_size     => ln_validated_page_size
            ) 
        );
        
        -- return actual json or fallback to empty {}
        if lt_dashboard_api_json_obj is not null 
        then
            -- convert json to clob
            l_msg_clob := lt_dashboard_api_json_obj.to_clob();
        else
            -- return empty json with pagination
            l_msg_clob := '{"pagination":{"page":1,"pageSize":1000,"totalRecords":0,"totalPages":0},"audit_results":[]}';
        end if;
        
        -- get total length of the clob
        l_total_length := dbms_lob.getlength(l_msg_clob);
        
        -- print json in chunks to handle large datasets
        while l_offset <= l_total_length loop
            htp.prn(dbms_lob.substr(l_msg_clob, l_chunk_size, l_offset));
            l_offset := l_offset + l_chunk_size;
        end loop;
        
    exception
        when others then
            -- log error with parameters
            logger.append_param(l_params, 'p_audit_code', p_audit_code);
            logger.append_param(l_params, 'p_company_name', p_company_name);
            logger.append_param(l_params, 'p_jaar', p_jaar);
            logger.append_param(l_params, 'p_maand', p_maand);
            logger.append_param(l_params, 'p_page', p_page);
            logger.append_param(l_params, 'p_page_size', p_page_size);
            logger.log_error(
                p_text   => 'Error in p_get_data',
                p_scope  => 'icca_dashboard_api_pkg.p_get_data',
                p_params => l_params
            );
            -- return error json
            htp.prn('{"error":"Internal server error"}');
            
    end p_get_data;
    --
    -----------------------------------------------------------------------------------------
    --
end icca_dashboard_api_pkg;
/
