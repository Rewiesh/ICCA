create or replace package icca_dashboard_api_pkg
as
    /*
        Package: icca_dashboard_api_pkg
        Purpose: API voor dashboard audit resultaten
        
        Functionaliteit:
        - Ophalen van audit resultaten vanuit icca_api_dashboard_vw
        - Genereren van JSON output voor dashboard
        - Filteren op audit code, company name, jaar en maand
        - Paginering voor efficiënte data overdracht
        - Chunked output voor grote datasets
        
        Technische opzet:
        - Types voor data structuur
        - Functies voor data ophalen en vullen van types
        - Functies voor conversie naar JSON
        - Procedure voor output met chunking
    */
    
    -- audit result type
    type t_audit_result is record
        (   company_id          number
        ,   audit_id            number
        ,   fom_id              number
        ,   company_name        varchar2(200)
        ,   name                varchar2(200)
        ,   region              varchar2(200)
        ,   date                varchar2(10)
        ,   audit_code          varchar2(100)
        ,   category_name       varchar2(100)
        ,   area_code           varchar2(500)
        ,   gk_grens            number
        ,   resultaat           number
        ,   element_type_value  varchar2(200)
        ,   error_type_value    varchar2(200)
        ,   fout                number
        ,   jaar                number
        ,   aantal_contr        number
        );
    type tt_audit_results is table of t_audit_result index by pls_integer;
    
    -- output type
    type t_dashboard_api is record
        (   audit_results   tt_audit_results
        ,   total_count     number
        ,   page            number
        ,   page_size       number
        ,   total_pages     number
        );
    
    procedure p_get_data(
        p_audit_code    in varchar2 default null,
        p_company_name  in varchar2 default null,
        p_jaar          in number   default null,
        p_maand         in number   default null,
        p_page          in number   default 1,
        p_page_size     in number   default 1000
    );

end icca_dashboard_api_pkg;
/
