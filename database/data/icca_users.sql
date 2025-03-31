begin
  merge into icca_users usr
    using ( select  'ADMIN'                                                             username
            ,       'ADMIN'                                                             password
            ,       (select id from icca_user_groups where system_name = 'UGP_ADMIN' )  ugp_id
            ,       (select id from icca_branches where name = 'Cleaning Industry' )    bch_id
            from    dual
          ) src
      on (src.username = usr.username)
    when not matched then
      insert (usr.username, usr.password, usr.ugp_id, usr.bch_id)
        values (src.username, src.password, src.ugp_id, src.bch_id)
    when matched then
      update set  usr.password  = src.password
    ;

  commit;
exception
  when others then
    rollback;
    dbms_output.put_line(sqlerrm);
end;
/
