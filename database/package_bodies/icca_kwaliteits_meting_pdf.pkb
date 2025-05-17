create or replace package body icca_kwaliteits_meting_pdf 
as
    --
    -- global variables
    gc_package        constant varchar2(31)   := $$plsql_unit|| '.';
    --
    --------------------------------------------------------------------------------------------------
    --
    function f_get_kmr_data( p_kte_id in number )
    return icca_kwaliteits_meting_pdf_template.t_kwaliteits_meeting_values
    is
       cursor c_fetch_data(b_kte_id in number)
       is 
            select *
            from MEDEWERKER 
            where medewerker_id = b_kte_id
            ;

        -- variables
        l_rte             icca_kwaliteits_meting_pdf_template.t_kwaliteits_meeting_values  := icca_kwaliteits_meting_pdf_template.t_kwaliteits_meeting_values();
        l_data            c_fetch_data%rowtype;
    begin
        --
        l_rte.rapport_nummer := 400;
        --
        return l_rte;
    exception
        when others then
        raise;
    end f_get_kmr_data;    
    --
    --
    ---------------------------------------------------------------------------------------------------
    --
    -- create pdf for kwaliteits meeting rapport
    function f_kwaliteits_rapport_pdf(   p_kte_id number )
    return blob
    is 
        l_kte_data icca_kwaliteits_meting_pdf_template.t_kwaliteits_meeting_values :=  icca_kwaliteits_meting_pdf_template.t_kwaliteits_meeting_values();
        lb_retval blob;
    begin
            l_kte_data   := f_get_kmr_data (p_kte_id => p_kte_id);

            lb_retval := icca_kwaliteits_meting_pdf_template.f_get_kwaliteits_meting_pdf( p_kwaliteits_meeting_values => l_kte_data
                                     );
        --
        return lb_retval;
        --                                           
    end f_kwaliteits_rapport_pdf;
    --
    --
    --
    ---------------------------------------------------------------------------------------------------
    --    
end icca_kwaliteits_meting_pdf;
/