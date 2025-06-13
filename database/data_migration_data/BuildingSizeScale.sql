INSERT INTO BuildingSizeScale (id, min_value, min_include, max_value, max_include, cbe_id)
VALUES (
    HEXTORAW(REPLACE('5fabe496-d7f7-493a-962e-38fdbe939826', '-', '')),
    250,
    1,
    499,
    1,
    (select id from icca_cat_buildingsize_scales where min_val = 250)
);

INSERT INTO BuildingSizeScale (id, min_value, min_include, max_value, max_include, cbe_id)
VALUES (
    HEXTORAW(REPLACE('5e276abc-1870-4326-a851-80b62bf35518', '-', '')),
    0,
    1,
    249,
    1,
    (select id from icca_cat_buildingsize_scales where min_val = 0)
);

INSERT INTO BuildingSizeScale (id, min_value, min_include, max_value, max_include, cbe_id)
VALUES (
    HEXTORAW(REPLACE('dd2b5bf3-adcc-4fcd-9df0-ef94d5af19c2', '-', '')),
    500,
    1,
    NULL,
    NULL,
    (select id from icca_cat_buildingsize_scales where min_val = 500)

);
