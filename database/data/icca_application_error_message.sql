declare
    procedure merge_error_msgs  (   p_name      in varchar2
                                ,   p_message   in varchar2
                                )
    is
    begin
        merge into icca_application_error_messages target
        using   (
                    select  upper(p_name)   as name
                    ,       p_message       as message           
                    from    dual
                ) source
        on  (   target.name = source.name   ) 
        when matched 
        then
            update set target.message  = source.message  
        when not matched 
        then
            insert  (   name
                    ,   message
                    )
            values  (   source.name 
                    ,   source.message
                    );
    end merge_error_msgs;
begin
    -- icca_branches
    merge_error_msgs( p_name => 'ICCA_BCH_NAME_UK_IDX1', p_message => 'Er bestaat al een branch met deze naam.');
    -- icca_user_groups
    merge_error_msgs( p_name => 'ICCA_UGP_NAME_SYSTEM_NAME_UK_IDX1', p_message => 'Er bestaat al een gebruikersgroep met deze naam en systeem naam.');    
    -- icca_users
    merge_error_msgs( p_name => 'ICCA_USR_USERNAME_UK_IDX1', p_message => 'Er bestaat al een gebruiker met deze gebruikersnaam.');
    -- merge_error_msgs( p_name => 'ICCA_USR_EMAIL_UK_IDX2', p_message => 'Er bestaat al een gebruiker met deze Email Adres.');
    -- icca_performers
    merge_error_msgs( p_name => 'ICCA_PFR_USR_ID_UK_IDX1', p_message => 'Er bestaat al een account voor deze performer.');      
    merge_error_msgs( p_name => 'ICCA_PFR_FIRST_LAST_NAME_UK_IDX2', p_message => 'Er bestaat al een performer met deze voornaam en achternaam');    
    -- icca_administrators
    merge_error_msgs( p_name => 'ICCA_ADM_USR_ID_UK_IDX1', p_message => 'Er bestaat al een account voor deze beheerder.');      
    merge_error_msgs( p_name => 'ICCA_ADM_FIRST_LAST_NAME_UK_IDX2', p_message => 'Er bestaat al een beheerder met deze voornaam en achternaam');       
    -- icca_clients
    merge_error_msgs( p_name => 'ICCA_CNT_USR_ID_UK_IDX1', p_message => 'Er bestaat al een account voor deze bedrijf.');
    merge_error_msgs( p_name => 'ICCA_CNT_COMPANY_NAME_UK_IDX2', p_message => 'Er bestaat al een klant met deze naam.');
    -- merge_error_msgs( p_name => 'ICCA_USR_EMAIL_UK2', p_message => 'Er bestaat al een gebruiker met deze Email Adres.');    
    -- icca_floors
    merge_error_msgs( p_name => 'ICCA_FLR_NAME_UK_IDX1', p_message => 'Er bestaat al een verdieping met deze naam.');
    merge_error_msgs( p_name => 'ICCA_FLR_CODE_UK_IDX2', p_message => 'Er bestaat al een verdieping met deze code.');
    -- icca_error_kinds
    merge_error_msgs( p_name => 'ICCA_EKD_NAME_UK_IDX1', p_message => 'Er bestaat al een error kind met deze naam.');    
    -- icca_error_categories
    merge_error_msgs( p_name => 'ICCA_ECE_NAME_UK_IDX1', p_message => 'Er bestaat al een error category met deze naam.');     
    -- icca_error_types
    merge_error_msgs( p_name => 'ICCA_ETE_NAME_ECE_ID_EKD_ID_UK_IDX1', p_message => 'Er bestaat al een error type met deze naam, error category en error kind.');    
    -- icca_areas
    merge_error_msgs( p_name => 'ICCA_ARA_NAME_UK_IDX1', p_message => 'Er bestaat al een area met deze naam en afkorting.');   
    -- icca_categories
    merge_error_msgs( p_name => 'ICCA_CAT_NAME_UK_IDX1', p_message => 'Er bestaat al een category met deze naam.');   
    -- icca_elementtypes
    merge_error_msgs( p_name => 'ICCA_EPE_NAME_UK_IDX1', p_message => 'Er bestaat al een elementtype met deze naam.');   
    -- icca_epe_areas
    merge_error_msgs( p_name => 'ICCA_ERA_EPE_ID_ARA_ID_UK_IDX1', p_message => 'Er bestaat al een elementtype met deze area combincatie.');   
    -- icca_kpi_elementen
    merge_error_msgs( p_name => 'ICCA_KET_NAME_UK_IDX1', p_message => 'Er bestaat al een KPI element met deze naam.');      
    -- icca_client_locations
    merge_error_msgs( p_name => 'ICCA_CLN_NAME_UK_IDX1', p_message => 'Er bestaat al een locatie met deze naam.');         
end;
/