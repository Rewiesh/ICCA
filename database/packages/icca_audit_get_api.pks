create or replace package icca_audit_get_api
as
    -- floors
    type t_floor is record
        (   id      number
        ,   name    varchar2(100)
        );
    type tt_floors is table of t_floor index by pls_integer;

    -- areas
    type t_area_elements is record
        (   element_id number );
    type tt_area_elements is table of t_area_elements index by pls_integer;

    type t_areas is record
        (   name            varchar2(100)
        ,   abbreviation    varchar2(100)
        ,   elements        tt_area_elements
        );
    type tt_areas is table of t_areas index by pls_integer;

    -- categories
    type t_category_min_element is record
        (   min1 number
        ,   min2 number
        ,   min3 number
        );
    
    type t_category_areas is record
        (   id              number
        ,   name            varchar2(100)
        ,   abbreviation    varchar2(100)
        );
    type tt_category_areas is table of t_category_areas index by pls_integer;

    type t_categories is record
        (   id              number
        ,   name            varchar2(50)
        ,   minimalElements t_category_min_element
        ,   areas           tt_category_areas
        );
    type tt_categories is table of t_categories index by pls_integer;

    -- elementtypes
    type t_elementtype is record
        (   id      number
        ,   name    varchar2(100)
        );
    type tt_elementtypes is table of t_elementtype index by pls_integer;

    -- errortypes
    type t_error_type is record
        (   id      number
        ,   name    varchar2(100)
        );
    type tt_error_types is table of t_error_type index by pls_integer;

    -- client categories
    type t_client_category is record
        (   cltId           number
        ,   clientID        number
        ,   clientName      varchar2(100)
        ,   categoryId      number
        ,   clientCategory  varchar2(100)
        );
    type tt_client_categories is table of t_client_category index by pls_integer;

    -- audits
    type t_kpi_element is record
        (   id              number
        ,   elementLabel    varchar2(100)
        ,   elementValue    varchar2(100)
        ,   elementComment  varchar2(100)
        );
    type tt_kpi_elements is table of t_kpi_element index by pls_integer;

    type t_audit is record
        (   id                  number
        ,   code                varchar2(100)
        ,   type                varchar2(100)
        ,   dateTime            date
        ,   clientName          varchar2(100)
        ,   clientLocation      varchar2(100)
        ,   clientLocationSize  varchar2(100)
        ,   isUnSaved           varchar2(100)
        ,   elements            tt_kpi_elements
        );
    type tt_audits is table of t_audit index by pls_integer;

    -- output
    type t_audit_api is record
        (   floors      tt_floors
        ,   areas       tt_areas
        ,   categories  tt_categories
        ,   elements    tt_elementtypes
        ,   errorTypes  tt_error_types
        ,   clients     tt_client_categories
        ,   audits      tt_audits
        );

    procedure p_get_data( p_username in varchar2 );

end icca_audit_get_api;
/
