begin
    merge into icca_cat_buildingsize_scales target
        using ( select  0       min_val         
                ,       1       min_sample_size 
                ,       249     max_val         
                ,       1       max_sample_size 
                from    dual
                union
                select  250     min_val         
                ,       1       min_sample_size 
                ,       499     max_val         
                ,       1       max_sample_size 
                from    dual
                union
                select  500     min_val         
                ,       1       min_sample_size 
                ,       null    max_val         
                ,       null    max_sample_size 
                from    dual
            ) src
    on (src.min_val = target.min_val)
    when not matched then
        insert (target.min_val, target.min_sample_size, target.max_val, target.max_sample_size)
            values (src.min_val, src.min_sample_size, src.max_val, src.max_sample_size)
    ;

    commit;
exception
  when others then
    rollback;
    dbms_output.put_line(sqlerrm);
end;
/