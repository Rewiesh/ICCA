begin
    -- maak een module aan voor het ophalen van audits
    ords.define_module(   p_module_name     => 'api'
                      ,   p_base_path       => 'api/'
                      ,   p_items_per_page  => 0
                      );
end;
/