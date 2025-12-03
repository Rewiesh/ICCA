   set serveroutput on;
declare
   l_blob blob;
begin
   dbms_output.put_line('Starting verification of f_test_hennie_dekker_dummy...');
    
    -- Call the new function
   l_blob := icca_pdf_generator.f_test_hennie_dekker_dummy;
    
    -- Check result
   if l_blob is not null then
      dbms_output.put_line('SUCCESS: BLOB received.');
      dbms_output.put_line('BLOB size: '
                           || dbms_lob.getlength(l_blob) || ' bytes');
   else
      dbms_output.put_line('FAILURE: BLOB is null.');
   end if;

exception
   when others then
      dbms_output.put_line('ERROR: ' || sqlerrm);
end;
/