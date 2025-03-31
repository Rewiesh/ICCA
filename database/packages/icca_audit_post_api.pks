create or replace package icca_audit_post_api
is
    -- Clients present when audit took place
    type t_present_client is record
        ( name varchar2(100) );
    type tt_present_clients is table of t_present_client index by pls_integer;

    -- audit data of kpi elements
    type t_kpi_element is record
        (   id                  number
        ,   audit_id            number
        ,   elements_audit_id   number
        ,   elementLabel        varchar2(100)
        ,   elementValue        varchar2(100)
        ,   elementComment      varchar2(100)
        );
    type tt_kpi_elements is table of t_kpi_element index by pls_integer;

    -- audit form errors
    type t_error is record
        (   element_type_id             number
        ,   error_type_id               number
        ,   log_book_remark             varchar2(4000)
        ,   technical_aspects_remark    varchar2(4000)
        ,   error_count                 number
        );
    type tt_error is table of t_error index by pls_integer;

    -- audit form
    type t_form is record
        (   id                  number
        ,   floor_id            number
        ,   category_id         number
        ,   form_date           date
        ,   area_code           varchar2(100)
        ,   counter_elements    number
        ,   remarks             varchar2(4000)
        ,   error               tt_errors
        );
    type tt_forms is table of t_form index by pls_integer;

    -- audit full record
    type t_audit is record
        (   id                  number
        ,   code                varchar2(100)
        ,   audit_date          date
        ,   signature_image_id  number
        ,   present_clients     tt_present_clients
        ,   kpi_elements        tt_kpi_elements
        ,   forms               tt_forms
        );

    procedure p_process_audit( p_audit_data in varchar2 );

end icca_audit_post_api;
/
