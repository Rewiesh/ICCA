create or replace package icca_user_activity_api 
as
    type t_audit_api_rec is record (
        performed_audits_count       number,
        last_client_name             varchar2(255),
        last_client_location_name    varchar2(255)
    );

    -- 
    procedure p_get_data(p_username in varchar2);

end icca_user_activity_api;
/