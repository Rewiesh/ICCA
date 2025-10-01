begin
    -- maak een module aan voor authentication
    ords.define_module(   p_module_name     => 'auth'
                      ,   p_base_path       => 'auth/'
                      ,   p_items_per_page  => 0
                      );
end;
/