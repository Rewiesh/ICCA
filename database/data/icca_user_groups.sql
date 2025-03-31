begin
  merge into icca_user_groups gebr
    using ( select  'UGP_ADMIN'             system_name
            ,       'ADMINISTRATORS'        name
            ,       null                    description
            from    dual
            union
            select  'UGP_PERFORMERS'   
            ,       'PERFORMERS'             
            ,       null                     
            from    dual
            union
            select  'UGP_CLIENTS'
            ,       'CLIENTS'
             ,       null                    
            from    dual
          ) src
      on (src.system_name = gebr.system_name)
    when not matched then
      insert (gebr.system_name, gebr.name, gebr.description)
        values (src.system_name, src.name, src.description)
    when matched then
      update set  gebr.name   = src.name
              ,   gebr.description  = src.description
    ;

  commit;
exception
  when others then
    rollback;
    dbms_output.put_line(sqlerrm);
end;
/


Categorie succesvol verwijderd.
Categorie gegevens succesvol verwerkt.
order by created_date desc
