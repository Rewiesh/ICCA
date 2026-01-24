set serveroutput on;
declare
    cursor c_get_old_data
    is
      select  adt.id                                              as old_adt_id
      ,       cnt.cnt_id                                          as new_cnt_id
      ,       bld.cln_id                                          as new_cln_id
      ,       adt.auditcode                                       as code
      ,       adt.type                                            as type
      ,       adt.date1                                           as audit_date
      ,       adt.lastcontroldate                                 as last_control_date
      ,       case when adt.isactive = 1 then 'Y' else 'N' end    as active
      ,       case when adt.activate = 1 then 'Y' else 'N' end    as activate
      ,       case when adt.isdone = 1 then 'Y' else 'N' end      as audit_completed
      from    audits2 adt
      join    users_client2 cnt on adt.nameclient_id = cnt.id
      join    buildings2 bld on adt.locationclient_id = bld.id
      where   cnt.cnt_id is not null
      and     bld.cln_id is not null
      and     adt.adt_id is not null
      and     adt.isdone = 1
      and     exists (
                select  1
                from    icca_audits adt2
                where   adt2.id   = adt.adt_id
                and     adt2.code = adt.auditcode
                and     adt2.audit_completed = 'N'
              );
    
    type t_old_data is table of c_get_old_data%rowtype;
    lt_old_data t_old_data;
    ln_adt_id number;
    ln_apr_id number;
    ln_existing_adt_id number;
    ln_existing_apr_id number;
    
    ln_total_audits number := 0;
    ln_new_audits number := 0;
    ln_reused_audits number := 0;
    ln_updated_audits number := 0;
    ln_new_adt_performers number := 0;
    ln_reused_adt_performers number := 0;
begin
    open    c_get_old_data;
    fetch   c_get_old_data bulk collect into lt_old_data;
    close   c_get_old_data;
    
    for i in 1 .. lt_old_data.count 
    loop
        begin
            ln_adt_id := null;
            ln_existing_adt_id := null;
            
            -- ============================================
            -- STAP 1: AUDIT MIGRATIE (met duplicate check)
            -- ============================================
            
            -- Check of audit al gemigreerd is via oude tabel
            begin
                select adt_id 
                into ln_existing_adt_id
                from audits2
                where id = lt_old_data(i).old_adt_id
                and adt_id is not null;
            exception
                when no_data_found then
                    ln_existing_adt_id := null;
            end;
            
            -- Als nog niet gemigreerd, check op code (auditcode is uniek)
            if ln_existing_adt_id is null then
                begin
                    select  id 
                    into    ln_existing_adt_id
                    from    icca_audits
                    where   code = lt_old_data(i).code
                    and     rownum = 1;
                exception
                    when no_data_found then
                        ln_existing_adt_id := null;
                end;
            end if;
            
            -- Audit aanmaken of bijwerken
            if ln_existing_adt_id is not null then
                ln_adt_id := ln_existing_adt_id;
                
                update icca_audits
                set type                = lt_old_data(i).type
                ,   audit_date          = lt_old_data(i).audit_date
                ,   last_control_date   = lt_old_data(i).last_control_date
                ,   cnt_id              = lt_old_data(i).new_cnt_id
                ,   cln_id              = lt_old_data(i).new_cln_id
                ,   active              = lt_old_data(i).active
                ,   activate            = lt_old_data(i).activate
                ,   audit_completed     = lt_old_data(i).audit_completed
                ,   migrated_data       = 'Y'
                where id = ln_adt_id;
                
                ln_updated_audits := ln_updated_audits + 1;
                dbms_output.put_line('✓ Audit updated - adt_id: ' || ln_adt_id || ' for code: ' || lt_old_data(i).code);
            else
                insert into icca_audits(    code                
                                        ,   type                
                                        ,   audit_date      
                                        ,   last_control_date    
                                        ,   cnt_id              
                                        ,   cln_id              
                                        ,   active              
                                        ,   activate            
                                        ,   audit_completed     
                                        ,   migrated_data       
                                    ) values (
                                            lt_old_data(i).code
                                        ,   lt_old_data(i).type
                                        ,   lt_old_data(i).audit_date
                                        ,   lt_old_data(i).last_control_date
                                        ,   lt_old_data(i).new_cnt_id
                                        ,   lt_old_data(i).new_cln_id
                                        ,   lt_old_data(i).active
                                        ,   lt_old_data(i).activate
                                        ,   lt_old_data(i).audit_completed
                                        ,   'Y'
                                        )
                        returning id into ln_adt_id;
                
                ln_new_audits := ln_new_audits + 1;
                dbms_output.put_line('✓ New audit created - adt_id: ' || ln_adt_id || ' for code: ' || lt_old_data(i).code);
            end if;
            
            -- Update oude audits2 tabel (idempotent)
            update  audits2
            set     adt_id = ln_adt_id
            where   id = lt_old_data(i).old_adt_id;
            
            -- ============================================
            -- STAP 2: AUDIT-PERFORMER MAPPING (met duplicate check)
            -- ============================================
            
            for auditor in (
                select  ln_adt_id       as new_adt_id
                ,       pfr1.id         as new_pfr_id
                ,       pfr.id          as old_pfr_id
                ,       apr.auditid     as old_adt_id
                from    auditauditor2 apr
                join    users_auditor pfr on apr.auditorid = pfr.id
                join    icca_users usr on usr.id = pfr.usr_id
                join    icca_performers pfr1 on pfr1.usr_id = usr.id
                where   pfr.usr_id is not null
                and     apr.auditid = lt_old_data(i).old_adt_id
            ) loop
                begin
                    ln_apr_id := null;
                    ln_existing_apr_id := null;
                    
                    -- Check of mapping al gemigreerd is via oude tabel
                    begin
                        select apr_id 
                        into ln_existing_apr_id
                        from auditauditor
                        where auditid = auditor.old_adt_id
                        and auditorid = auditor.old_pfr_id
                        and apr_id is not null;
                    exception
                        when no_data_found then
                            ln_existing_apr_id := null;
                    end;
                    
                    -- Als nog niet gemigreerd, check in icca_adt_performers
                    if ln_existing_apr_id is null then
                        begin
                            select id
                            into ln_existing_apr_id
                            from icca_adt_performers
                            where adt_id = auditor.new_adt_id
                            and pfr_id = auditor.new_pfr_id
                            and rownum = 1;
                        exception
                            when no_data_found then
                                ln_existing_apr_id := null;
                        end;
                    end if;
                    
                    -- Mapping aanmaken of hergebruiken
                    if ln_existing_apr_id is not null then
                        ln_apr_id := ln_existing_apr_id;
                        ln_reused_adt_performers := ln_reused_adt_performers + 1;
                        dbms_output.put_line('  ✓ Reusing performer mapping - apr_id: ' || ln_apr_id || ' (pfr_id: ' || auditor.new_pfr_id || ')');
                    else
                        insert into icca_adt_performers(    adt_id       
                                                        ,   pfr_id       
                                                        ,   migrated_data
                                                    ) values (
                                                            auditor.new_adt_id
                                                        ,   auditor.new_pfr_id
                                                        ,   'Y'
                                                    )
                                            returning id into ln_apr_id;
                        
                        ln_new_adt_performers := ln_new_adt_performers + 1;
                        dbms_output.put_line('  ✓ New performer mapping - apr_id: ' || ln_apr_id || ' (pfr_id: ' || auditor.new_pfr_id || ')');
                    end if;
                    
                    -- Update auditauditor tabel met apr_id (idempotent)
                    update  auditauditor
                    set     apr_id = ln_apr_id
                    where   auditid = auditor.old_adt_id
                    and     auditorid = auditor.old_pfr_id;
                    
                exception
                    when others then
                        dbms_output.put_line('  ⚠ Error migrating audit-performer mapping: ' || sqlerrm);
                        dbms_output.put_line('    old_pfr_id: ' || auditor.old_pfr_id || ', new_pfr_id: ' || auditor.new_pfr_id);
                end;
            end loop;
            
            ln_total_audits := ln_total_audits + 1;
            
        exception
            when others then
                dbms_output.put_line('✗ Error processing audit: ' || lt_old_data(i).code || ' - ' || sqlerrm);
                dbms_output.put_line('  old_adt_id: ' || lt_old_data(i).old_adt_id);
                continue;
        end;
    end loop;
    
    commit;
    
    -- Summary rapport
    dbms_output.put_line('');
    dbms_output.put_line('========================================');
    dbms_output.put_line('AUDIT MIGRATION SUMMARY');
    dbms_output.put_line('========================================');
    dbms_output.put_line('Total audits2 processed:         ' || ln_total_audits);
    dbms_output.put_line('  - New audits2 created:         ' || ln_new_audits);
    dbms_output.put_line('  - Existing audits2 updated:    ' || ln_updated_audits);
    dbms_output.put_line('');
    dbms_output.put_line('Audit-Performer mappings:');
    dbms_output.put_line('  - New mappings created:       ' || ln_new_adt_performers);
    dbms_output.put_line('  - Existing mappings reused:   ' || ln_reused_adt_performers);
    dbms_output.put_line('========================================');
end;
/



set serveroutput on;
declare
    cursor c_get_signatures is
        select  adt.id                      as old_adt_id
        ,       adt.adt_id                  as new_adt_id
        ,       adt.locationmanagersignimage as old_image_id
        ,       img.doc_id                  as new_doc_id
        from    audits2 adt
        join    images img on img.imageid = adt.locationmanagersignimage
        where   adt.adt_id is not null
        and     img.doc_id is not null
        and     adt.locationmanagersignimage is not null
        ;
    
    ln_total_updated number := 0;
    ln_already_correct number := 0;
    ln_newly_updated number := 0;
begin
    dbms_output.put_line('========================================');
    dbms_output.put_line('AUDIT SIGNATURE IMAGE UPDATE');
    dbms_output.put_line('========================================');
    dbms_output.put_line('');
    
    for sig in c_get_signatures loop
        begin
            -- Check of signature_image_id al correct is
            declare
                ln_current_doc_id number;
            begin
                select signature_image_id
                into ln_current_doc_id
                from icca_audits
                where id = sig.new_adt_id;
                
                if ln_current_doc_id = sig.new_doc_id then
                    ln_already_correct := ln_already_correct + 1;
                    dbms_output.put_line('✓ Already correct - adt_id: ' || sig.new_adt_id || ' → doc_id: ' || sig.new_doc_id);
                else
                    -- Update de signature_image_id
                    update icca_audits
                    set signature_image_id = sig.new_doc_id
                    where id = sig.new_adt_id;
                    
                    ln_newly_updated := ln_newly_updated + 1;
                    dbms_output.put_line('✓ Updated - adt_id: ' || sig.new_adt_id || ' → doc_id: ' || sig.new_doc_id || ' (was: ' || nvl(to_char(ln_current_doc_id), 'NULL') || ')');
                end if;
            exception
                when no_data_found then
                    dbms_output.put_line('⚠ Audit not found - adt_id: ' || sig.new_adt_id);
            end;
            
            ln_total_updated := ln_total_updated + 1;
            
        exception
            when others then
                dbms_output.put_line('✗ Error updating audit ' || sig.new_adt_id || ': ' || sqlerrm);
        end;
    end loop;
    
    commit;
    
    -- Summary
    dbms_output.put_line('');
    dbms_output.put_line('========================================');
    dbms_output.put_line('UPDATE SUMMARY');
    dbms_output.put_line('========================================');
    dbms_output.put_line('Total audits2 processed:         ' || ln_total_updated);
    dbms_output.put_line('  - Already correct:            ' || ln_already_correct);
    dbms_output.put_line('  - Newly updated:              ' || ln_newly_updated);
    dbms_output.put_line('========================================');
end;
/


set serveroutput on;
declare
    cursor c_get_signatures is
        select  adt.id                      as old_adt_id
        ,       adt.adt_id                  as new_adt_id
        ,       adt.locationmanagersignimage as old_image_id
        ,       img.doc_id                  as new_doc_id
        from    audits2 adt
        join    images img on img.imageid = adt.locationmanagersignimage
        where   adt.adt_id is not null
        and     img.doc_id is not null
        and     adt.locationmanagersignimage is not null
        ;
    
    ln_total_updated number := 0;
    ln_already_correct number := 0;
    ln_newly_updated number := 0;
begin
    dbms_output.put_line('========================================');
    dbms_output.put_line('AUDIT SIGNATURE IMAGE UPDATE');
    dbms_output.put_line('========================================');
    dbms_output.put_line('');
    
    for sig in c_get_signatures loop
        begin
            -- Check of signature_image_id al correct is
            declare
                ln_current_doc_id number;
            begin
                select signature_image_id
                into ln_current_doc_id
                from icca_audits
                where id = sig.new_adt_id;
                
                if ln_current_doc_id = sig.new_doc_id then
                    ln_already_correct := ln_already_correct + 1;
                    dbms_output.put_line('✓ Already correct - adt_id: ' || sig.new_adt_id || ' → doc_id: ' || sig.new_doc_id);
                else
                    -- Update de signature_image_id
                    update icca_audits
                    set signature_image_id = sig.new_doc_id
                    where id = sig.new_adt_id;
                    
                    ln_newly_updated := ln_newly_updated + 1;
                    dbms_output.put_line('✓ Updated - adt_id: ' || sig.new_adt_id || ' → doc_id: ' || sig.new_doc_id || ' (was: ' || nvl(to_char(ln_current_doc_id), 'NULL') || ')');
                end if;
            exception
                when no_data_found then
                    dbms_output.put_line('⚠ Audit not found - adt_id: ' || sig.new_adt_id);
            end;
            
            ln_total_updated := ln_total_updated + 1;
            
        exception
            when others then
                dbms_output.put_line('✗ Error updating audit ' || sig.new_adt_id || ': ' || sqlerrm);
        end;
    end loop;
    
    commit;
    
    -- Summary
    dbms_output.put_line('');
    dbms_output.put_line('========================================');
    dbms_output.put_line('UPDATE SUMMARY');
    dbms_output.put_line('========================================');
    dbms_output.put_line('Total audits2 processed:         ' || ln_total_updated);
    dbms_output.put_line('  - Already correct:            ' || ln_already_correct);
    dbms_output.put_line('  - Newly updated:              ' || ln_newly_updated);
    dbms_output.put_line('========================================');
end;
/