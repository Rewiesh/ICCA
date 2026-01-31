select  *
from    icca_audits
where   code = '17738'
;

select cat.name as categorie_naam,
      res.counter_elements as tel_element,
      res.approve_limit as goedkeurgrens,
      res.counter_errors as aantal_behaalde_fouten,
      res.score as cijfer,
      case
        when res.is_sufficient = 'Y' then 'Voldoende'
        else 'Onvoldoende'
      end as beoordeling
from icca_adt_results res
join icca_categories cat on cat.id = res.cat_id
where res.adt_id = 18468
order by cat.name
;

select  *
from    icca_incoming_messages
where   json_value(message, '$.audit.Code') = '17738'
order by id desc;

declare
    ln_ige_id   number;
    ln_audit_id number;
begin
    icca_audit_post_api.p_msg_handler( 1648, ln_audit_id );
end;
/

select  *
from    icca_categories
;

select  *
from    icca_error_types
