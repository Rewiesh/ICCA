begin
    dbms_utility.compile_schema('ICCA', false);
end;
/

prompt invalid_objects:

select  *
from    all_objects where status <> 'VALID'
;