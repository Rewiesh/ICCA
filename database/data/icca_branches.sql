begin
  merge into icca_branches bch
    using ( select  'Cleaning Industry'             name
            from    dual
          ) src
      on (src.name = bch.name)
    when not matched then
      insert (bch.name)
        values (src.name)
    ;

  commit;
exception
  when others then
    rollback;
    dbms_output.put_line(sqlerrm);
end;
/
