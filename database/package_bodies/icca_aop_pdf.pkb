create or replace package body icca_aop_pdf
is

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
--global variables

    function f_get_imgs_html(p_doc_ids varchar2, p_duplicate_number number default null, p_duplicate_tech number default null,  p_img_type in varchar2)
    return clob
    is
        cursor c_get_docs(b_doc_ids varchar2, b_row_size number, b_img_type in varchar2)
        is
            with w_docs_list as (
                select  column_value as id
                ,       rownum       as rn
                from    table(
                            apex_string.split(b_doc_ids, ',')
                            -- apex_string.split(5401, ',')
                )
                join    (
                        select 1
                        from dual
                        connect by level <= case
                                                when b_img_type = 'TECHNICAL_ASPECTS'
                                                    then nvl(p_duplicate_tech, 1)
                                                else
                                                    nvl(p_duplicate_number, 1)
                                            end
                ) on (1=1)
            )
            ,
            w_fom as (
                    select  case
                                when fom.migrated_data = 'Y' then fom.migrated_area_code
                                else flr.name||'-'||ara.abbreviation||'.'||fom.area_number
                            end as area_code
                    ,       fom.id fom_id
                    from    icca_adt_forms      fom
                    join    icca_floors         flr on fom.flr_id = flr.id
                    join    icca_areas          ara on fom.ara_id = ara.id
            )
            ,
            w_img_data as(
                select      'https://icca-dashboard.maxapex.net/' || doc.file_url as img_data
                ,           doc.id                                           as id
                ,           docs_list.rn                                     as rn
                -- ,           substr(technical_aspects_remark, 1, 150)         as technical_aspects_remark
                ,           case
                                when length( fom.area_code || ': '|| technical_aspects_remark  ) > 150
                                then substr( fom.area_code || ': '|| technical_aspects_remark  , 1, 147) || '...'
                                else fom.area_code ||': ' ||technical_aspects_remark
                            end as technical_aspects_remark
                -- ,           technical_aspects_remark                         as technical_aspects_remark
                ,           mime_type                                        as mime_type
                from        icca_documents doc
                join        w_docs_list docs_list on docs_list.id = doc.id
                left join   icca_fom_errors frs on (doc.id = frs.technical_aspects_image_id and b_img_type = 'TECHNICAL_ASPECTS')
                left join   w_fom fom on frs.fom_id = fom.fom_id
                order by docs_list.rn asc
            )
           ,    w_img_rows as (
                    select  ceil(rn / b_row_size )                as row_num
                    ,       max(ceil(rn / b_row_size )) over()    as max_row_num
                    ,       rn
                    ,       decode(b_img_type, 'TECHNICAL_ASPECTS', technical_aspects_remark, 'Foto ' || rn) as img_description
                    ,       id                                     as id
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

    lv_const_spacing_params json_object_t := json_object_t(q'[
    {
        "horizontal": {
            "row_spacing": {
                "even": {
                    "first_page": { "last": 190, "not_last": 230 },
                    "other_pages": { "last": 300, "not_last": 280 }
                },
                "odd": { "last": 0, "not_last": 50 }
            },
            "extra_spacing": { "last": 6, "not_last": 28 },
            "cell_dimensions": ['370px', '270px'],
            "under_three_cell_dimensions": ['270px', '170px'],
            "image_dimensions": ['auto', 'auto']
        },
        "vertical": {
            "row_spacing": {
                "even": {
                    "first_page": { "last": 0, "not_last": 0 },
                    "other_pages": { "last": 25, "not_last": 35 }
                },
                "odd": { "last": 0, "not_last": 0 }
            },
            "extra_spacing": { "last": 0, "not_last": 0 },
            "cell_dimensions" : ['1080px', '1920px'],
            "under_three_cell_dimensions": ['270px', '370px'],
            "image_dimensions" : ['270px', '370px']
            }
    }
    ]');

    lv_const_orientation_mode constant varchar2(10) := 'VERTICAL';

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
    ln_cell_width            varchar2(100) := lv_const_spacing_params.get_object(lower(lv_const_orientation_mode)).get_Array('cell_dimensions').get_string(0);
    ln_cell_height           varchar2(100) := lv_const_spacing_params.get_object(lower(lv_const_orientation_mode)).get_Array('cell_dimensions').get_string(1);

    -- Less than 3 images cell sizing
    ln_under_three_cell_width   varchar2(100) := lv_const_spacing_params.get_object(lower(lv_const_orientation_mode)).get_Array('under_three_cell_dimensions').get_string(0);
    ln_under_three_cell_height  varchar2(100) := lv_const_spacing_params.get_object(lower(lv_const_orientation_mode)).get_Array('under_three_cell_dimensions').get_string(1);

    -- Image size
    ln_img_width            varchar2(100) := lv_const_spacing_params.get_object(lower(lv_const_orientation_mode)).get_Array('image_dimensions').get_string(0);
    ln_img_height           varchar2(100) := lv_const_spacing_params.get_object(lower(lv_const_orientation_mode)).get_Array('image_dimensions').get_string(1);

    lv_image_header_html varchar2(1000);

    begin

        open    c_get_docs( b_doc_ids => p_doc_ids , b_row_size => ln_const_col_cnt,  b_img_type => p_img_type);
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

                lv_image_header_html := case p_img_type when 'TECHNICAL_ASPECTS' then
                                                    '<th style="padding: 3px 5px; font-size:9px; line-height:1.0; text-align: left; border-top:1px solid #696969; border-left:1px solid #696969; border-right:1px solid #696969; border-bottom:none;">'
                                            else    '<th style="padding: 5px; text-align: center; border-top:1px solid #696969; border-left:1px solid #696969; border-right:1px solid #696969; border-bottom:none;">'
                                        end;

               dbms_lob.append(lc_html,
                            lv_image_header_html
                        ||      '<b>' || lt_docs(j).img_description ||'</b>'
                        ||  '</th>'
               )
                ;

                -- Append empty table headers for spacing between header columns, note that this is NOT done before 1st header and after 3rd header
                if j < least(i + ln_const_col_cnt - 1, lt_docs.count) then
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
                    '<td style="width:'|| case when ( lt_docs.count <= 2 ) then ln_under_three_cell_width else ln_cell_width end ||'; height:' || case when ( lt_docs.count <= 2 ) then ln_under_three_cell_height else ln_cell_height end ||';border:1px solid #dfd81d; vertical-align:middle;">'
                    ----------------------------------------------------** Actual Image **-------------------
                    -- || '<img src="data:image/'|| lt_docs(k).mime_type || ';base64,' || lt_docs(k).img_data || '" ' --* actual image
                    || '<img src="'|| lt_docs(k).img_data ||'" ' --* URL src real
                    -- || '<img src="'|| 'https://icca-dashboard.maxapex.net/uploads/cad2f5401cd34d1da8f1f10847f939b7.png' ||'" ' --* URL src tst should be commented out TODO: Remove these lines
                    -- || '<img src="data:image/'|| lt_docs(k).mime_type || ';base64,' || 'lv_img_based64' || '" ' --* for logging html
                    -- || '<img src="data:image/'|| lt_docs(k).mime_type || ';base64,' || lv_img_based64 || '" '   --* for testing img
                    || 'style="max-width: ' || ln_cell_width || '; max-height: ' || ln_cell_height || '; width:' || ln_img_width || '; height:' || ln_img_height ||'; object-fit:contain; display:block; border: 1px solid #dfd81d;">'
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
                                                    when lt_docs(i).row_num = lt_docs(i).max_row_num then --ln_even_other_page_last   --* space when moving from page 2+ to next page and LAST PAGE
                                                        case when p_img_type = 'TECHNICAL_ASPECTS' then 15
                                                        else ln_even_other_page_last end
                                                        -- else 0 end
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
            if ln_row_space_height = 0 then
                dbms_lob.append(lc_html, '<tr style="height:' || ln_row_space_height ||'px; border:none";><td colspan="'|| to_char((ln_const_col_cnt*2-1)) ||'" style="height:0px; border:none;"></td></tr>');
            else
                dbms_lob.append(lc_html, '<tr style="height:' || ln_row_space_height ||'px; border:none";><td colspan="'|| to_char((ln_const_col_cnt*2-1)) ||'" style="height:10px; border:none;"></td></tr>');
            end if;
            --

            -- * append extra table row for spacing so "Algemene Opmerkingen"elements aren't too close to header image
            if  mod(lt_docs(i).row_num, 2) = 0 and not lt_docs(i).row_num = lt_docs(i).max_row_num
            then
                null;
                -- dbms_lob.append(lc_html, '<tr style="height:' || ln_extra_not_last ||'px; border:none";><td colspan="'|| to_char((ln_const_col_cnt*2-1)) ||'" style="height:10px; border:none;"></td></tr>');
            elsif mod(lt_docs(i).row_num, 2) = 0 and lt_docs(i).row_num = lt_docs(i).max_row_num
            then
                null;
                -- dbms_lob.append(lc_html, '<tr style="height:' || ln_extra_last ||'px; border:none";><td colspan="'|| to_char((ln_const_col_cnt*2-1)) ||'" style="height:10px; border:none;"></td></tr>');
            end if;



        end loop;

       dbms_lob.append(lc_html, '</table>');

        -- print_clob(lc_html);


        return lc_html;

    exception
        when others then
            if c_get_docs%isopen then close c_get_docs; end if;
            raise;
    end f_get_imgs_html;

    function f_main_get_images(p_doc_log_book_ids varchar2, p_doc_tech_aspects_ids varchar2,  p_duplicate_number number default null, p_duplicate_tech number default null)
    return clob
    is
        l_rtn_val                       clob;
        l_technical_aspects_header_html varchar2(1000);-- := '-- <p style="page-break-before: always;';
        l_log_book_img_count            number;
        l_page_break                    boolean;
        l_log_book_header_html          varchar2(1000) := '<div style="font-size: 18px; font-weight: bold; font-family: Arial, sans-serif;">' ||
                                                            '<p>Opmerking Element:</p>' ||
                                                          '</div>';
    begin

        -- Create temporary CLOB
        dbms_lob.createtemporary(l_rtn_val, true);

        -- Calculate page break based on log book images
        if p_doc_log_book_ids is not null then
            l_log_book_img_count := nvl(regexp_count(p_doc_log_book_ids, '[^,]+'), 0);

            l_log_book_img_count := l_log_book_img_count * nvl(p_duplicate_number, 1);

            l_page_break := mod(l_log_book_img_count, 6) != 0;

            -- Append logbook header and images
            dbms_lob.append(l_rtn_val , l_log_book_header_html);
            dbms_lob.append(l_rtn_val, f_get_imgs_html(p_doc_ids => p_doc_log_book_ids, p_img_type => 'LOG_BOOK', p_duplicate_number => p_duplicate_number, p_duplicate_tech => p_duplicate_tech));
        end if;


        -- * TODO
        -- l_page_break := false;

        -- Append tech aspect header and images
        if p_doc_tech_aspects_ids is not null then
            -- if p_doc_log_book_ids is not null then

            -- Add header with optional page break if logbook images exist
                l_technical_aspects_header_html := '<div style="' ||
                        case
                            when l_page_break then 'page-break-before: always; '
                            else ''
                        end ||
                        'font-size: 18px; font-weight: bold; font-family: Arial, sans-serif; ">' ||
                        '<p>Technische Aspecten:</p>' ||
                        '</div>';
                dbms_lob.append(l_rtn_val, l_technical_aspects_header_html);
            -- end if;

            -- Append tech aspect images
            dbms_lob.append(l_rtn_val, f_get_imgs_html(p_doc_ids => p_doc_tech_aspects_ids, p_img_type => 'TECHNICAL_ASPECTS', p_duplicate_number => p_duplicate_number , p_duplicate_tech => p_duplicate_tech));
        end if;

        -- print_clob(l_rtn_val);

        return l_rtn_val;

    end f_main_get_images;

    procedure show_inline_pdf (   p_output_blob      in blob
                              ,   p_output_filename  in varchar2
                              ,   p_output_mime_type in varchar2
                              )
    is
        l_pdf blob := p_output_blob;
    begin
        sys.htp.init;
        sys.owa_util.mime_header( 'application/pdf', false );
        sys.htp.p('Content-length: ' || sys.dbms_lob.getlength( l_pdf));
        sys.htp.p('Content-Disposition: inline; filename="' || p_output_filename || '"');
        sys.htp.p('Cache-Control: max-age=10');  -- tell the browser to cache for 10s, adjust as necessary
        sys.owa_util.http_header_close;
        sys.wpg_docload.download_file( l_pdf);
    --   apex_application.stop_apex_engine;
    end show_inline_pdf;
end icca_aop_pdf;
/