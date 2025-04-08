create or replace package body icca_audit_get_api
as
    /*
        Start: Fill types function
    */
    --
    -----------------------------------------------------------------------------------------
    --  FLOORS TYPE
    function f_floors_tab
    return tt_floors
    is  
        --
        -- cursors
        cursor c_get_floors
        is
            select  id
            ,       name
            from    icca_floors
            ;
        -- 
        -- variables
        lt_floors       tt_floors;
        ln_floor_idx    pls_integer := 0;
    begin
        --
        for r_floor in c_get_floors
        loop
            --
            ln_floor_idx := ln_floor_idx + 1;
            lt_floors( ln_floor_idx ).id    := r_floor.id;
            lt_floors( ln_floor_idx ).name  := r_floor.name;
            --
        end loop;
        --
        return lt_floors;
        --
    end f_floors_tab;
    --
    -----------------------------------------------------------------------------------------
    --  AREAS TYPE
    function f_area_elements_tab( p_ara_id in number )
    return tt_area_elements
    is
        --
        -- cursors
        cursor c_get_area_elements( b_ara_id in number )
        is
            select  id
            from    icca_epe_areas era
            where   era.ara_id = b_ara_id
            ;
        -- 
        -- variables
        lt_area_elements    tt_area_elements;
        ln_area_element_idx pls_integer := 0;
    begin
        --
        for r_area_element in c_get_area_elements(p_ara_id)
        loop
            --
            ln_area_element_idx := ln_area_element_idx + 1;
            lt_area_elements( ln_area_element_idx ).element_id := r_area_element.id;
            --
        end loop;
        --
        return lt_area_elements;
        --
    end f_area_elements_tab;
    --
    function f_areas_tab
    return tt_areas
    is
        --
        -- cursors
        cursor c_get_areas
        is
            select  *
            from    icca_areas          ara 
            where   active = 'Y'
            ;
        -- 
        -- variables
        lt_areas        tt_areas;
        ln_areas_idx    pls_integer := 0;        
    begin
        --
        for r_area in c_get_areas
        loop
            --
            ln_areas_idx := ln_areas_idx + 1;
            lt_areas( ln_areas_idx ).name           := r_area.name;
            lt_areas( ln_areas_idx ).abbreviation   := r_area.abbreviation;
            lt_areas( ln_areas_idx ).elements       := f_area_elements_tab( r_area.id );
            --
        end loop;
        --
        return lt_areas;
        --
    end f_areas_tab;
    --
    -----------------------------------------------------------------------------------------
    --  CATEGORY TYPE    
    function f_category_min_element_rec( p_cat_id in number )
    return t_category_min_element
    is
        --
        -- cursors
        cursor c_get_category_min_element( b_cat_id in number )
        is
            select  (   select  min_size_range
                        from    icca_cat_limits               clm
                        join    icca_cat_buildingsize_scales  cbe on cbe.id = clm.cbe_id
                        where   cbe.min_val = 0
                        and     clm.cat_id = cat.id
                    ) min1
            ,       (   select  min_size_range
                        from    icca_cat_limits               clm
                        join    icca_cat_buildingsize_scales  cbe on cbe.id = clm.cbe_id
                        where   cbe.min_val = 250
                        and     clm.cat_id = cat.id
                    ) min2    
            ,       (   select  min_size_range
                        from    icca_cat_limits               clm
                        join    icca_cat_buildingsize_scales  cbe on cbe.id = clm.cbe_id
                        where   cbe.min_val = 500
                        and     clm.cat_id = cat.id
                    ) min3            
            from    icca_categories cat
            where   cat.id = b_cat_id
            ;
        -- 
        -- variables
        lr_get_category_min_element c_get_category_min_element%rowtype;
        lr_category_min_element     t_category_min_element;
    begin
        --
        open    c_get_category_min_element( p_cat_id );
        fetch   c_get_category_min_element
        into    lr_get_category_min_element;
        close   c_get_category_min_element;
        --
        lr_category_min_element.min1 := lr_get_category_min_element.min1;
        lr_category_min_element.min2 := lr_get_category_min_element.min2;
        lr_category_min_element.min3 := lr_get_category_min_element.min3;
        --
        return lr_category_min_element;
        --
    end f_category_min_element_rec;
    --
    --
    function f_category_areas_tab( p_cat_id in number )
    return tt_category_areas
    is
        --
        -- cursors
        cursor c_get_category_areas( b_cat_id in number )
        is
            select  ara.id 
            ,       ara.name
            ,       ara.abbreviation
            from    icca_ara_categories aat
            join    icca_areas          ara on ara.id = aat.ara_id
            where   aat.cat_id = b_cat_id
            ;
        -- 
        -- variables
        lt_category_areas       tt_category_areas;
        ln_category_areas_idx   pls_integer := 0;                  
    begin
        --
        for r_category_area in c_get_category_areas( p_cat_id )
        loop
            --
            ln_category_areas_idx := ln_category_areas_idx + 1;
            lt_category_areas( ln_category_areas_idx ).id           := r_category_area.id;
            lt_category_areas( ln_category_areas_idx ).name         := r_category_area.name;
            lt_category_areas( ln_category_areas_idx ).abbreviation := r_category_area.abbreviation;
            --
        end loop;
        --
        return lt_category_areas;
        --
    end f_category_areas_tab;
    --
    --
    function f_categories_tab
    return tt_categories
    is
        --
        -- cursors
        cursor c_get_categories
        is
            select  cat.id 
            ,       cat.name
            from    icca_categories cat
            where   cat.active = 'Y'
            ;
        -- 
        -- variables
        lt_categories       tt_categories;
        ln_categories_idx   pls_integer := 0;                  
    begin
        --
        for r_category in c_get_categories
        loop
            --
            ln_categories_idx := ln_categories_idx + 1;
            lt_categories( ln_categories_idx ).id               := r_category.id;
            lt_categories( ln_categories_idx ).name             := r_category.name;
            lt_categories( ln_categories_idx ).minimalElements  := f_category_min_element_rec ( r_category.id );
            lt_categories( ln_categories_idx ).areas            := f_category_areas_tab( r_category.id );
            --
        end loop;
        --
        return lt_categories;
        --
    end f_categories_tab;  
    --
    -----------------------------------------------------------------------------------------
    --  ELEMENTTYPES      
    function f_elementtypes_tab
    return tt_elementtypes
    is
        --
        -- cursors
        cursor c_get_elementtypes
        is
            select  epe.id 
            ,       epe.name
            from    icca_elementtypes epe
            ;
        -- 
        -- variables
        lt_elementtypes     tt_elementtypes;
        ln_elementtypes_idx pls_integer := 0;                  
    begin
        --
        for r_elementtype in c_get_elementtypes
        loop
            --
            ln_elementtypes_idx := ln_elementtypes_idx + 1;
            lt_elementtypes( ln_elementtypes_idx ).id   := r_elementtype.id;
            lt_elementtypes( ln_elementtypes_idx ).name := r_elementtype.name;
            --
        end loop;
        --
        return lt_elementtypes;
        --
    end f_elementtypes_tab;    
    --
    -----------------------------------------------------------------------------------------
    --  ERROR_TYPES      
    function f_error_types_tab
    return tt_error_types
    is
        --
        -- cursors
        cursor c_get_error_types
        is
            select  ete.id 
            ,       ete.name
            from    icca_error_types ete
            ;
        -- 
        -- variables
        lt_error_types      tt_error_types;
        ln_error_types_idx pls_integer := 0;                  
    begin
        --
        for r_error_type in c_get_error_types
        loop
            --
            ln_error_types_idx := ln_error_types_idx + 1;
            lt_error_types( ln_error_types_idx ).id     := r_error_type.id;
            lt_error_types( ln_error_types_idx ).name   := r_error_type.name;
            --
        end loop;
        --
        return lt_error_types;
        --
    end f_error_types_tab; 
    --
    -----------------------------------------------------------------------------------------
    --  CLIENT_CATEGORIES      
    function f_client_categories_tab( p_username in varchar2 )
    return tt_client_categories
    is
        --
        -- cursors
        cursor c_client_categories( b_username in varchar2 )
        is
            select  clt.id            cltId
            ,       cnt.id            clientId
            ,       cnt.company_name  clientName
            ,       cat.id            categoryId
            ,       cat.name          clientCategory
            from    icca_cat_clients  clt
            join    icca_categories   cat on cat.id = clt.cat_id
            join    icca_clients      cnt on cnt.id = clt.cnt_id
            join    icca_pfr_clients  pnt on cnt.id = pnt.cnt_id
            join    icca_performers   pfr on pfr.id = pnt.pfr_id
            join    icca_users        usr on usr.id = pfr.usr_id
            where   upper(usr.username) = upper(b_username)
            and     usr.active = 'Y'
            ;
        -- 
        -- variables
        lt_client_categories        tt_client_categories;
        ln_client_categories_idx    pls_integer := 0;                  
    begin
        --
        for r_client_category in c_client_categories( p_username )
        loop
            --
            ln_client_categories_idx := ln_client_categories_idx + 1;
            lt_client_categories( ln_client_categories_idx ).cltId            := r_client_category.cltId;
            lt_client_categories( ln_client_categories_idx ).clientID         := r_client_category.clientID;
            lt_client_categories( ln_client_categories_idx ).clientName       := r_client_category.clientName;
            lt_client_categories( ln_client_categories_idx ).categoryId       := r_client_category.categoryId;     
            lt_client_categories( ln_client_categories_idx ).clientCategory   := r_client_category.clientCategory;            
            --
        end loop;
        --
        return lt_client_categories;
        --
    end f_client_categories_tab;
    --
    -----------------------------------------------------------------------------------------
    --  AUDITS
    function f_kpi_elements_tab( p_cnt_id in number )
    return tt_kpi_elements
    is
        --
        -- cursors
        cursor c_kpi_elements( b_cnt_id in number )
        is
            select  ket.id    id
            ,       ket.name  elementLabel
            ,       ''        elementValue
            ,       ''        elementComment
            from    icca_ket_clients    kcn
            join    icca_kpi_elementen  ket on ket.id = kcn.ket_id
            where   kcn.cnt_id = b_cnt_id
            and     ket.active = 'Y'
            ;
        -- 
        -- variables
        lt_kpi_elements     tt_kpi_elements;
        ln_kpi_elements_idx pls_integer := 0;                  
    begin
        --
        for r_kpi_element in c_kpi_elements( p_cnt_id )
        loop
            --
            ln_kpi_elements_idx := ln_kpi_elements_idx + 1;
            lt_kpi_elements( ln_kpi_elements_idx ).id               := r_kpi_element.id;
            lt_kpi_elements( ln_kpi_elements_idx ).elementLabel     := r_kpi_element.elementLabel;
            lt_kpi_elements( ln_kpi_elements_idx ).elementValue     := r_kpi_element.elementValue;
            lt_kpi_elements( ln_kpi_elements_idx ).elementComment   := r_kpi_element.elementComment;
            --
        end loop;
        --
        return lt_kpi_elements;
        --
    end f_kpi_elements_tab;
    --
    --
    function f_audits_tab( p_username in varchar2 )
    return tt_audits
    is
        --
        -- cursors
        cursor c_audits( b_username in varchar2 )
        is
            select  adt.id              id
            ,       cnt.id              cnt_id
            ,       adt.code            code
            ,       adt.type            type
            ,       adt.audit_date      dateTime
            ,       cnt.company_name    clientName
            ,       cln.name            clientLocation
            ,       cln.location_size   clientLocationSize
            ,       ''                  isUnSaved
            from    icca_audits           adt
            join    icca_clients          cnt on cnt.id = adt.cnt_id
            join    icca_client_locations cln on cln.id = adt.cln_id
            join    icca_adt_performers   apr on adt.id = apr.adt_id
            join    icca_performers       pfr on pfr.id = apr.pfr_id
            join    icca_users            usr on usr.id = pfr.usr_id
            join    icca_pfr_clients      pnt on ( pfr.id = pnt.pfr_id and pnt.cnt_id = cnt.id)
            where   upper(usr.username) = upper(b_username)
            and     adt.active              = 'Y'
            and     adt.activate            = 'Y'
            and     adt.audit_completed     = 'N'
            ;
        -- 
        -- variables
        lt_audits     tt_audits;
        ln_audits_idx pls_integer := 0;                  
    begin
        --
        for r_audit in c_audits( p_username )
        loop
            --
            ln_audits_idx := ln_audits_idx + 1;
            lt_audits( ln_audits_idx ).id                   := r_audit.id;
            lt_audits( ln_audits_idx ).code                 := r_audit.code;
            lt_audits( ln_audits_idx ).type                 := r_audit.type;
            lt_audits( ln_audits_idx ).dateTime             := r_audit.dateTime;
            lt_audits( ln_audits_idx ).clientName           := r_audit.clientName;
            lt_audits( ln_audits_idx ).clientLocation       := r_audit.clientLocation;
            lt_audits( ln_audits_idx ).clientLocationSize   := r_audit.clientLocationSize;
            lt_audits( ln_audits_idx ).isUnSaved            := r_audit.isUnSaved;
            lt_audits( ln_audits_idx ).elements             := f_kpi_elements_tab( r_audit.cnt_id );
            --
        end loop;
        --
        return lt_audits;
        --
    end f_audits_tab;
    --
    -----------------------------------------------------------------------------------------
    --  OUTPUT TYPE
    function f_audit_api_rec( p_username in varchar2 )
    return t_audit_api
    is
        -- 
        -- variables
        lr_audit_api_rec t_audit_api;
    begin
        --
        lr_audit_api_rec.floors     := f_floors_tab;
        lr_audit_api_rec.areas      := f_areas_tab;
        lr_audit_api_rec.categories := f_categories_tab;
        lr_audit_api_rec.elements   := f_elementtypes_tab;
        lr_audit_api_rec.errorTypes := f_error_types_tab;
        lr_audit_api_rec.clients    := f_client_categories_tab( p_username );
        lr_audit_api_rec.audits     := f_audits_tab( p_username );
        --
        return lr_audit_api_rec;
        --
    end f_audit_api_rec;
    --
    -----------------------------------------------------------------------------------------
    --
    /*
        End: Fill types function
    */
    --
    -----------------------------------------------------------------------------------------
    --    
    /*
        Start: Create json objects
    */    
    --
    -----------------------------------------------------------------------------------------
    --  FLOOR JSON     
    function f_floors_json_array_obj( p_floors_tab in tt_floors)
    return json_array_t
    is
        -- 
        -- variables    
        l_floors_json_array_obj json_array_t := json_array_t();
    begin
        --
        for i in 1..p_floors_tab.count
        loop
            declare
                l_one_floor_json_obj json_object_t := json_object_t();
            begin
                l_one_floor_json_obj.put( 'id'  , p_floors_tab(i).id );
                l_one_floor_json_obj.put( 'name', p_floors_tab(i).name );
                l_floors_json_array_obj.append( l_one_floor_json_obj );
            end;            
        end loop;
        --
        return l_floors_json_array_obj;
        --
    end f_floors_json_array_obj;
    --
    -----------------------------------------------------------------------------------------
    --  AREAS JSON 
    function f_area_elements_json_array_obj( p_area_elements_tab in tt_area_elements)
    return json_array_t
    is
        -- 
        -- variables    
        l_area_elements_json_array_obj json_array_t := json_array_t();        
    begin
        --
        for i in 1..p_area_elements_tab.count
        loop
            declare
                l_one_area_element_json_obj json_object_t := json_object_t();
            begin
                l_one_area_element_json_obj.put( 'elementId' , p_area_elements_tab(i).element_id );
                l_area_elements_json_array_obj.append( l_one_area_element_json_obj );
            end;            
        end loop;
        --
        return l_area_elements_json_array_obj;
        --    
    end f_area_elements_json_array_obj;
    --      
    -- 
    function f_areas_json_array_obj( p_areas_tab in tt_areas)
    return json_array_t
    is
        -- 
        -- variables    
        l_areas_json_array_obj json_array_t := json_array_t();        
    begin
        --
        for i in 1..p_areas_tab.count
        loop
            declare
                l_one_area_json_obj json_object_t := json_object_t();
            begin
                l_one_area_json_obj.put( 'name'         , p_areas_tab(i).name );
                l_one_area_json_obj.put( 'abbreviation' , p_areas_tab(i).abbreviation );
                l_one_area_json_obj.put( 'elements'     , f_area_elements_json_array_obj ( p_areas_tab(i).elements ) );
                l_areas_json_array_obj.append( l_one_area_json_obj );
            end;            
        end loop;
        --
        return l_areas_json_array_obj;
        --    
    end f_areas_json_array_obj;
    --
    -----------------------------------------------------------------------------------------
    --  CATEGORIES JSON
    function f_category_min_elements_json_array_obj( p_category_min_element in t_category_min_element)
    return json_array_t
    is
        -- 
        -- variables    
        l_category_min_elements_json_array_obj json_array_t := json_array_t();        
    begin
        --
        l_category_min_elements_json_array_obj.append(p_category_min_element.min1);
        l_category_min_elements_json_array_obj.append(p_category_min_element.min2);
        l_category_min_elements_json_array_obj.append(p_category_min_element.min3);
        --
        return l_category_min_elements_json_array_obj;
        --    
    end f_category_min_elements_json_array_obj;
    --
    --
    function f_category_areas_json_array_obj( p_category_areas in tt_category_areas )
    return json_array_t
    is
        -- 
        -- variables     
        l_category_areas_json_array json_array_t := json_array_t();
    begin
        --
        for i in 1..p_category_areas.count
        loop
            declare
                l_one_category_area_json_obj json_object_t := json_object_t();
            begin
                l_one_category_area_json_obj.put( 'id'              , p_category_areas(i).id );
                l_one_category_area_json_obj.put( 'name'            , p_category_areas(i).name );
                l_one_category_area_json_obj.put( 'abbreviation'    , p_category_areas(i).abbreviation );
                l_category_areas_json_array.append( l_one_category_area_json_obj );
            end;            
        end loop;
        --
        return l_category_areas_json_array;
        --    
    end f_category_areas_json_array_obj;
    --
    --
    function f_categories_json_array_obj( p_categories_tab in tt_categories)
    return json_array_t
    is
        -- 
        -- variables    
        l_categories_json_array_obj json_array_t := json_array_t();        
    begin
        --
        for i in 1..p_categories_tab.count
        loop
            declare
                l_one_category_json_obj json_object_t := json_object_t();
            begin
                l_one_category_json_obj.put( 'id'               , p_categories_tab(i).id );
                l_one_category_json_obj.put( 'name'             , p_categories_tab(i).name );
                l_one_category_json_obj.put( 'minimalElements'  , f_category_min_elements_json_array_obj ( p_categories_tab(i).minimalElements ) );
                l_one_category_json_obj.put( 'areas'            , f_category_areas_json_array_obj ( p_categories_tab(i).areas ) );
                l_categories_json_array_obj.append( l_one_category_json_obj );
            end;            
        end loop;
        --
        return l_categories_json_array_obj;
        --    
    end f_categories_json_array_obj;    
    --
    -----------------------------------------------------------------------------------------
    --  ELEMENTTYPES
    function f_elementtypes_json_array_obj( p_elementtypes_tab in tt_elementtypes)
    return json_array_t
    is
        -- 
        -- variables    
        l_elementtypes_json_array_obj json_array_t := json_array_t();        
    begin
        --
        for i in 1..p_elementtypes_tab.count
        loop
            declare
                l_one_elementtypes_json_obj json_object_t := json_object_t();
            begin
                l_one_elementtypes_json_obj.put( 'id'   , p_elementtypes_tab(i).id );
                l_one_elementtypes_json_obj.put( 'name' , p_elementtypes_tab(i).name );
                l_elementtypes_json_array_obj.append( l_one_elementtypes_json_obj );
            end;            
        end loop;
        --
        return l_elementtypes_json_array_obj;
        --    
    end f_elementtypes_json_array_obj;
    --
    -----------------------------------------------------------------------------------------
    --  ERROR_TYPES
    function f_error_types_json_array_obj( p_error_types_tab in tt_error_types)
    return json_array_t
    is
        -- 
        -- variables    
        l_error_types_json_array_obj json_array_t := json_array_t();        
    begin
        --
        for i in 1..p_error_types_tab.count
        loop
            declare
                l_one_error_types_json_obj json_object_t := json_object_t();
            begin
                l_one_error_types_json_obj.put( 'id'   , p_error_types_tab(i).id );
                l_one_error_types_json_obj.put( 'name' , p_error_types_tab(i).name );
                l_error_types_json_array_obj.append( l_one_error_types_json_obj );
            end;            
        end loop;
        --
        return l_error_types_json_array_obj;
        --    
    end f_error_types_json_array_obj;
    --
    -----------------------------------------------------------------------------------------
    --  CLIENT_CATEGORIES
    function f_client_categories_json_array_obj( p_client_categories_tab in tt_client_categories)
    return json_array_t
    is
        -- 
        -- variables    
        l_client_categories_json_array_obj json_array_t := json_array_t();        
    begin
        --
        for i in 1..p_client_categories_tab.count
        loop
            declare
                l_one_client_categories_json_obj json_object_t := json_object_t();
            begin
                l_one_client_categories_json_obj.put( 'cltId'           , p_client_categories_tab(i).cltId );
                l_one_client_categories_json_obj.put( 'clientID'        , p_client_categories_tab(i).clientID );
                l_one_client_categories_json_obj.put( 'clientName'      , p_client_categories_tab(i).clientName );
                l_one_client_categories_json_obj.put( 'categoryId'      , p_client_categories_tab(i).categoryId );
                l_one_client_categories_json_obj.put( 'clientCategory'  , p_client_categories_tab(i).clientCategory );
                l_client_categories_json_array_obj.append( l_one_client_categories_json_obj );
            end;            
        end loop;
        --
        return l_client_categories_json_array_obj;
        --    
    end f_client_categories_json_array_obj;
    --
    -----------------------------------------------------------------------------------------
    --  AUDITS
    function f_kpi_elements_json_array_obj( p_kpi_elements_tab in tt_kpi_elements)
    return json_array_t
    is
        -- 
        -- variables    
        l_kpi_elements_json_array_obj json_array_t := json_array_t();        
    begin
        --
        for i in 1..p_kpi_elements_tab.count
        loop
            -- exit when i = 100;
            declare
                l_one_kpi_elements_json_obj json_object_t := json_object_t();
            begin
                l_one_kpi_elements_json_obj.put( 'id'               , p_kpi_elements_tab(i).id );
                l_one_kpi_elements_json_obj.put( 'elementLabel'     , icca_json_util.f_sanitize_json_string( p_kpi_elements_tab(i).elementLabel ) );
                l_one_kpi_elements_json_obj.put( 'elementValue'     , icca_json_util.f_sanitize_json_string( p_kpi_elements_tab(i).elementValue ) );
                l_one_kpi_elements_json_obj.put( 'elementComment'   , icca_json_util.f_sanitize_json_string( p_kpi_elements_tab(i).elementComment ) );
                l_kpi_elements_json_array_obj.append( l_one_kpi_elements_json_obj );
            end;            
        end loop;
        --
        return l_kpi_elements_json_array_obj;
        --    
    end f_kpi_elements_json_array_obj;
    --
    --
    function f_audits_json_array_obj( p_audits_categories_tab in tt_audits)
    return json_array_t
    is
        -- 
        -- variables    
        l_audits_json_array_obj json_array_t := json_array_t();        
    begin
        --
        for i in 1..p_audits_categories_tab.count
        loop
            declare
                l_one_audits_json_obj json_object_t := json_object_t();
            begin
                l_one_audits_json_obj.put( 'id'                 , p_audits_categories_tab(i).id );
                l_one_audits_json_obj.put( 'code'               , icca_json_util.f_sanitize_json_string( p_audits_categories_tab(i).code ) );
                l_one_audits_json_obj.put( 'type'               , icca_json_util.f_sanitize_json_string( p_audits_categories_tab(i).type ) );
                l_one_audits_json_obj.put( 'dateTime'           , p_audits_categories_tab(i).dateTime );
                l_one_audits_json_obj.put( 'clientName'         , icca_json_util.f_sanitize_json_string( p_audits_categories_tab(i).clientName ) );
                l_one_audits_json_obj.put( 'clientLocation'     , icca_json_util.f_sanitize_json_string( p_audits_categories_tab(i).clientLocation ) );
                l_one_audits_json_obj.put( 'clientLocationSize' , icca_json_util.f_sanitize_json_string( p_audits_categories_tab(i).clientLocationSize ) );
                l_one_audits_json_obj.put( 'isUnSaved'          , icca_json_util.f_sanitize_json_string( p_audits_categories_tab(i).isUnSaved ) );
                l_one_audits_json_obj.put( 'elements'           , f_kpi_elements_json_array_obj( p_audits_categories_tab(i).elements ) );
                l_audits_json_array_obj.append( l_one_audits_json_obj );
            end;            
        end loop;
        --
        return l_audits_json_array_obj;
        --    
    end f_audits_json_array_obj;    
    --
    -----------------------------------------------------------------------------------------
    --  OUTPUT JSON
    function f_audit_api_json_obj( p_audit_api_rec in t_audit_api )
    return json_object_t
    is
        -- 
        -- variables
        lr_audit_api_type_to_json_obj json_object_t  :=  json_object_t();
    begin
        -- build final json message
        --
        -- add floors to output
        if p_audit_api_rec.floors.count > 0
        then
            lr_audit_api_type_to_json_obj.put('floors', f_floors_json_array_obj( p_audit_api_rec.floors ));
        end if;
        --
        -- add areas to output
        if p_audit_api_rec.areas.count > 0
        then
            lr_audit_api_type_to_json_obj.put('areas', f_areas_json_array_obj( p_audit_api_rec.areas ));
        end if;
        --
        -- add categories to output
        if p_audit_api_rec.categories.count > 0
        then
            lr_audit_api_type_to_json_obj.put('categories', f_categories_json_array_obj( p_audit_api_rec.categories ));
        end if;
        --
        -- add elements to output
        if p_audit_api_rec.elements.count > 0
        then
            lr_audit_api_type_to_json_obj.put('elements', f_elementtypes_json_array_obj( p_audit_api_rec.elements ));
        end if;
        --
        -- add errorTypes to output
        if p_audit_api_rec.errorTypes.count > 0
        then
            lr_audit_api_type_to_json_obj.put('errorTypes', f_error_types_json_array_obj( p_audit_api_rec.errorTypes ));
        end if;
        --
        -- add clients to output
         if p_audit_api_rec.clients.count > 0
         then
             lr_audit_api_type_to_json_obj.put('clients', f_client_categories_json_array_obj( p_audit_api_rec.clients ));
         end if;
        --  
        -- add audits to output
        if p_audit_api_rec.audits.count > 0
        then
            lr_audit_api_type_to_json_obj.put('audits', f_audits_json_array_obj( p_audit_api_rec.audits ));
        end if;
        --          
        return lr_audit_api_type_to_json_obj;
        --
    end f_audit_api_json_obj;
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
    procedure p_get_data( p_username in varchar2 )
    is
        -- Variables
        lt_audit_api_json_obj   json_object_t;
        l_msg_clob              clob;
        l_chunk_size            constant pls_integer := 32000; -- Max chunk size for HTP.P
        l_offset                pls_integer := 1;
        l_total_length          pls_integer;
    begin
        -- Convert data to JSON object
        lt_audit_api_json_obj := f_audit_api_json_obj( f_audit_api_rec( p_username ) );

        -- Return actual JSON or fallback to empty {}
        if lt_audit_api_json_obj is not null 
        then
            -- Convert JSON to CLOB
            l_msg_clob := lt_audit_api_json_obj.to_clob();
        else
            -- return empty JSON
            l_msg_clob := '{}';
        end if;

        -- Get total length of the CLOB
        l_total_length := dbms_lob.getlength(l_msg_clob);

        -- Print JSON in chunks
        while l_offset <= l_total_length loop
            htp.p(dbms_lob.substr(l_msg_clob, l_chunk_size, l_offset));
            l_offset := l_offset + l_chunk_size;
        end loop;
    end p_get_data;
    --
    -----------------------------------------------------------------------------------------
    --
end icca_audit_get_api;
/
