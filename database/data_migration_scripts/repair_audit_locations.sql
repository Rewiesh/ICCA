set serveroutput on;
declare
    cursor c_fix_audit_locations is
        select  adt.adt_id                  as audit_id
        ,       adt.auditcode               as code
        ,       bld.cln_id                  as new_location_id
        ,       ia.cln_id                   as current_location_id
        from    audits2 adt
        join    buildings2 bld on adt.locationclient_id = bld.id
        join    icca_audits ia on adt.adt_id = ia.id
        where   adt.adt_id is not null
        and     bld.cln_id is not null
        and     ia.cln_id != bld.cln_id; -- Only select where there is a mismatch

    ln_updated_count number := 0;
begin
    dbms_output.put_line('========================================');
    dbms_output.put_line('REPAIR AUDIT LOCATIONS');
    dbms_output.put_line('========================================');

    for r in c_fix_audit_locations loop
        begin
            update icca_audits
            set    cln_id = r.new_location_id
            where  id = r.audit_id;
            
            ln_updated_count := ln_updated_count + 1;
            dbms_output.put_line('✓ Fixed Audit ' || r.code || ' (ID: ' || r.audit_id || '): Location ' || r.current_location_id || ' -> ' || r.new_location_id);
            
        exception
            when others then
                dbms_output.put_line('✗ Error fixing audit ' || r.code || ': ' || sqlerrm);
        end;
    end loop;
    
    commit;
    
    dbms_output.put_line('');
    dbms_output.put_line('Total audits repaired: ' || ln_updated_count);
    dbms_output.put_line('========================================');
end;
/
