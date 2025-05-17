create or replace package  icca_kwaliteits_meting_pdf_template
is
    --
    -- type om de waarde op te halen van data package
    --
    type t_kwaliteits_meeting_values is record 
    (   rapport_nummer     varchar2(1000)
    );
    --
    -- Function die de pdf genereert voor de kwaliteits meting rapport
    --
    Function f_get_kwaliteits_meting_pdf (p_kwaliteits_meeting_values  t_kwaliteits_meeting_values)
    return blob;
    --
    --
end icca_kwaliteits_meting_pdf_template;
/