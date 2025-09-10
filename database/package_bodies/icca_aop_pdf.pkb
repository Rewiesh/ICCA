create or replace package body icca_aop_pdf
is
--global variables

    function f_get_imgs_html(p_doc_ids varchar2, p_duplicate_number number default null)
    return clob
    is
        cursor c_get_docs(b_doc_ids varchar2)
        is
            with w_img_data as(
                select  apex_web_service.blob2clobbase64(image_data) as img_data
                ,       row_number() over (order by id) as rn
                ,       mime_type
                from    icca_documents doc
                join    (
                    select 1 from dual connect by level <= nvl(p_duplicate_number, 1)
                ) on (1=1)
                where   id in (
                            select  column_value as id
                            from    table(
                                        apex_string.split(b_doc_ids, ',')
                                        -- apex_string.split('281,284,555,666,777,888', ',')
                            )
                )
            )
           ,    w_img_rows as (
                    select  ceil(rn / 3)                as row_num
                    ,       max(ceil(rn / 3)) over()    as max_row_num
                    ,       rn
                    ,       mime_type
                    ,       img_data
                    from    w_img_data
                )
                select * from w_img_rows;

        type tt_docs is table of c_get_docs%rowtype;
        lt_docs tt_docs;

        lc_html                     clob;
        ln_const_col_cnt constant   number := 3;
        ln_row_space_height         number;

        lv_img_based64 clob := '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
XGL6hA+iAAAAAElFTkSuQmCC';

    lv_const_spacing_params json_object_t := json_object_t(q'[
    {
        "horizontal": {
            "row_spacing": {
                "even": {
                    "first_page": { "last": 190, "not_last": 190 },
                    "other_pages": { "last": 240, "not_last": 220 }
                },
                "odd": { "last": 0, "not_last": 25 }
            },
            "extra_spacing": { "last": 5, "not_last": 28 },
            "cell_dimensions": [500, 370],
            "image_dimensions": [500, 370]
        },
        "vertical": {
            "row_spacing": {
                "even": {
                    "first_page": { "last": 10, "not_last": 10 },
                    "other_pages": { "last": 60, "not_last": 40 }
                },
                "odd": { "last": 0, "not_last": 10 }
            },
            "extra_spacing": { "last": 5, "not_last": 28 },
            "cell_dimensions" : [1080, 1920],
            "image_dimensions" : [270, 370]
            }
    }
    ]');

    lv_const_orientation_mode constant varchar2(10) := 'HORIZONTAL';

    --row spacing - even
    ln_even_first_page_last      number := lv_const_spacing_params.get_object(lower(lv_const_orientation_mode)).get_object('row_spacing').get_object('even').get_object('first_page').get_number('last');
    ln_even_first_page_not_last  number := lv_const_spacing_params.get_object(lower(lv_const_orientation_mode)).get_object('row_spacing').get_object('even').get_object('first_page').get_number('not_last');
    ln_even_other_page_last      number := lv_const_spacing_params.get_object(lower(lv_const_orientation_mode)).get_object('row_spacing').get_object('even').get_object('other_pages').get_number('last');
    ln_even_other_page_not_last  number := lv_const_spacing_params.get_object(lower(lv_const_orientation_mode)).get_object('row_spacing').get_object('even').get_object('other_pages').get_number('not_last');

    -- row spacing - odd
    ln_odd_last             number := lv_const_spacing_params.get_object(lower(lv_const_orientation_mode)).get_object('row_spacing').get_object('odd').get_number('last');
    ln_odd_not_last         number := lv_const_spacing_params.get_object(lower(lv_const_orientation_mode)).get_object('row_spacing').get_object('odd').get_number('not_last');

    -- extra spacing
    ln_extra_last           number := lv_const_spacing_params.get_object(lower(lv_const_orientation_mode)).get_object('extra_spacing').get_number('last');
    ln_extra_not_last       number := lv_const_spacing_params.get_object(lower(lv_const_orientation_mode)).get_object('extra_spacing').get_number('not_last');

    -- Cell size
    ln_cell_width            varchar2(100) := lv_const_spacing_params.get_object(lower(lv_const_orientation_mode)).get_Array('cell_dimensions').get_Number(0);
    ln_cell_height           varchar2(100) := lv_const_spacing_params.get_object(lower(lv_const_orientation_mode)).get_Array('cell_dimensions').get_Number(1);

    -- Image size
    ln_img_width            varchar2(100) := lv_const_spacing_params.get_object(lower(lv_const_orientation_mode)).get_Array('image_dimensions').get_Number(0);
    ln_img_height           varchar2(100) := lv_const_spacing_params.get_object(lower(lv_const_orientation_mode)).get_Array('image_dimensions').get_Number(1);

    procedure print_clob (p_clob in clob)
    is
        l_offset     int := 1;
    begin
        loop
        exit when l_offset > dbms_lob.getlength(p_clob);
            dbms_output.put_line( dbms_lob.substr( p_clob, 255, l_offset ) );
        l_offset := l_offset + 255;
        end loop;
    end print_clob;


    begin

        open    c_get_docs( b_doc_ids => p_doc_ids );
        fetch   c_get_docs bulk collect into lt_docs;
        close   c_get_docs;

        if lt_docs.count < 1 then
            return null;
        end if;

        /* Create main table, which we will start appending to in loop width:auto; max-height: 1cm;*/
        lc_html := '<table style="width:auto; max-height: 1cm; margin:0 auto;text-align: center; border-collapse: separate; border-spacing: 40px 10px;">';

        for i in 1..lt_docs.count by ln_const_col_cnt loop

          dbms_lob.append(lc_html, '<tr>');

            -- Header Text(and styling)
            for j in i..least(i + ln_const_col_cnt  - 1, lt_docs.count) loop
            -- for j in i..(i + ln_const_col_cnt  - 1) loop
               dbms_lob.append(lc_html,
                            '<th style="padding: 5px; border-top:1px solid #696969; border-left:1px solid #696969; border-right:1px solid #696969; border-bottom:none;">'
                        ||      '<b>Foto ' || lt_docs(j).rn ||'</b>'
                        ||  '</th>'
               )
                        ;
                -- Append empty table headers for spacing between header columns, note that this is NOT done before 1st header and after 3rd header
                if j < least(i + ln_const_col_cnt - 1, lt_docs.count) then
                -- if j < (i + ln_const_col_cnt - 1) then
                    dbms_lob.append(lc_html, '<th style="width:40px; border:none;"></th>');
                end if;

            end loop;

            -- Close row
            dbms_lob.append(lc_html,  '</tr>');

            -- Start row for images
            lc_html := lc_html || '<tr>';

            /*
                Add images for this group
                Might need to play around with width and height depending on if horizontal / vertical images
            */
            for k in i..least(i + ln_const_col_cnt - 1, lt_docs.count) loop
            -- for k in i..(i + ln_const_col_cnt - 1) loop
                dbms_lob.append(lc_html,
                    '<td style="width:'|| case when lt_docs.count <= 2 then ln_img_width else ln_cell_width end ||'px; height:' || case when lt_docs.count <= 2 then ln_img_height else ln_cell_height end ||'px;border:1px solid #dfd81d; vertical-align:middle;">'
                    || '<img src="data:image/'|| lt_docs(k).mime_type || ';base64,' || lt_docs(k).img_data || '" ' --* actual image
                    -- || '<img src="data:image/'|| lt_docs(k).mime_type || ';base64,' || 'lv_img_based64' || '" ' --* for logging html
                    -- || '<img src="data:image/'|| lt_docs(k).mime_type || ';base64,' || lv_img_based64 || '" '   --* for testing img
                    || 'style="max-width: ' || ln_cell_width || 'px; max-height: ' || ln_cell_height || 'px; width:' || ln_img_width || 'auto; height:' || ln_img_height ||'auto; object-fit:contain; display:block; border: 1px solid #dfd81d;">'
                    -- || 'style="max-width: ' || ln_cell_width || 'px; max-height: ' || ln_cell_height || 'px; width:' || '1080' || 'px; height:' || '1920' ||'px; object-fit:contain; display:block; border: 1px solid #dfd81d;">'
                    || '</td>'
                );

                -- Append empty table headers for spacing between image columns, note that this is NOT done before 1st image and after 3rd image
                if k < least(i + ln_const_col_cnt - 1, lt_docs.count) then
                -- if k < (i + ln_const_col_cnt - 1) then
                    dbms_lob.append(lc_html, '<td style="border:none"></td>');
                end if;
            end loop;

            dbms_lob.append(lc_html, '</tr>');

            /*
                Calculation for divider width between rows.
                If width between 2 rows is set too small, header appears on one page and then image on another,
                which is also why this is done conditionally as we do not want spacing between rows on one page to be too large
                Last pages have more spacing as we will also conditionally place a last td element for more spacing so next elements aren't too close to header image
            */
            if  mod(lt_docs(i).row_num, 2) = 0  then
                ln_row_space_height := case
                                            when lt_docs(i).row_num > 2 then
                                                case
                                                    when lt_docs(i).row_num = lt_docs(i).max_row_num then ln_even_other_page_last   --* space when moving from page 2+ to next page and LAST PAGE
                                                    else ln_even_other_page_not_last end                                                --* space when moving from page 2+ to next page and NOT LAST PAGE
                                            else
                                                case
                                                    when lt_docs(i).row_num = lt_docs(i).max_row_num then ln_even_first_page_last  --* space when moving from page 1 to 2 and LAST PAGE
                                                    else ln_even_first_page_not_last end                                               --* space when moving from page 1 to 2 and NOT LAST PAGE
                                        end;
            else
                ln_row_space_height := case when lt_docs(i).row_num = lt_docs(i).max_row_num then ln_odd_last else ln_odd_not_last end; --*  between 2 rows on one page,
                                                                                                                  --* less spacing when last row as "Algemene Opmerkingen" table will go under last img
            end if;

            -- Divider between rows
            dbms_lob.append(lc_html, '<tr style="height:' || ln_row_space_height ||'px; border:none";><td colspan="'|| to_char((ln_const_col_cnt*2-1)) ||'" style="height:10px; border:1px solid blue;"></td></tr>');
            --

            -- * append extra table row for spacing so "Algemene Opmerkingen"elements aren't too close to header image
            if  mod(lt_docs(i).row_num, 2) = 0 and not lt_docs(i).row_num = lt_docs(i).max_row_num
            then
                dbms_lob.append(lc_html, '<tr style="height:' || ln_extra_not_last ||'px; border:none";><td colspan="'|| to_char((ln_const_col_cnt*2-1)) ||'" style="height:10px; border:3px dotted red;"></td></tr>');
            elsif mod(lt_docs(i).row_num, 2) = 0 and lt_docs(i).row_num = lt_docs(i).max_row_num
            then
                dbms_lob.append(lc_html, '<tr style="height:' || ln_extra_last ||'px; border:none";><td colspan="'|| to_char((ln_const_col_cnt*2-1)) ||'" style="height:10px; border:3px dotted red;"></td></tr>');
            end if;



        end loop;

       dbms_lob.append(lc_html, '</table>');

        print_clob(lc_html);


        return lc_html;

    exception
        when others then
            if c_get_docs%isopen then close c_get_docs; end if;
            raise;
    end;
end icca_aop_pdf;