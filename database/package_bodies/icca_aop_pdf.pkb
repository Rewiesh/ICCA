create or replace package body icca_aop_pdf
is
--global variables

    function f_get_imgs_html(p_doc_ids varchar2)
    return clob
    is
        cursor c_get_docs(b_doc_ids varchar2)
        is
            with w_img_data as(
                select  apex_web_service.blob2clobbase64(image_data) as img_data
                ,       row_number() over (order by id) as rn
                ,       mime_type
                from    icca_documents
                where   id in (
                            select  column_value as id
                            from    table(
                                        apex_string.split(b_doc_ids, ',')
                                        -- apex_string.split('281,284,555,666,777,888', ',')
                            )
                )
            )
           ,    w_img_rows as (
                    select  ceil(rn / 3)as row_num
                    ,       rn
                    ,       mime_type
                    ,       img_data
                    from    w_img_data
                )
                select * from w_img_rows;

        type tt_docs is table of c_get_docs%rowtype;
        lt_docs tt_docs;

        lc_html                     clob;
        lv_const_col_cnt constant   number := 3;

        i                           number;

        /*
        type t_cell is record(img_number number, img_html clob);

        type tt_row is table of t_cell;

        type tt_rows is table of tt_row index by pls_integer;

        lt_rows tt_rows := tt_rows();
        ln_row_idx number;
        */
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

        -- for i in 1..lt_docs.count loop
        --     dbms_output.put_line(lt_docs(i).row_num || ' ' || lt_docs(i).rn || ' => ' || substr(lt_docs(i).img_data,1 ,20));
        -- end loop;

        -- for i in 1..lt_docs.count loop
        --     ln_row_idx := ceil(i / lv_const_col_cnt);
        --         -- dbms_output.put_line(ln_row_idx);
        --         -- for j in 1..lv_const_col_cnt loop
        --         --     lt_rows(ln_row_idx) := tt_row(i).t_cell(img_number => lt_docs(j).rn, img_html =>  substr(lt_docs(j).img_data,1 ,20));
        --         -- end loop;

        --     if not lt_rows.exists(ln_row_idx) then lt_rows(ln_row_idx) := tt_row(); end if;
        --     lt_rows(ln_row_idx).extend;
        --     -- Looks confusing but just accesses current idx
        --     lt_rows(ln_row_idx)(lt_rows(ln_row_idx).count ) := t_cell(img_number => lt_docs(i).rn, img_html => substr(lt_docs(i).img_data,1 ,20));
        -- end loop;



        -- for i in 1..lt_rows.count loop
        --     dbms_output.put_line('Bak ' || i);
        --     dbms_output.new_line;
        --     for j in 1..lt_rows(i).count loop
        --         dbms_output.put_line(lt_rows(i)(j).img_number);
        --     end loop;
        -- end loop;


        /* Create main table */
        lc_html := '<table style="width: 100%; text-align: center;">';
        for i in 1..lt_docs.count by lv_const_col_cnt loop

                lc_html := lc_html || '<thead><tr>';

            for j in i..least(i + lv_const_col_cnt  - 1, lt_docs.count) loop
               dbms_lob.append(lc_html, '<th style="padding: 10px; border:none;">'
                        ||      '<b>Foto' || lt_docs(j).rn ||'</b>'
                        ||  '</th>'
               )
                        ;
            end loop;

                lc_html := lc_html || '</tr></thead>';

        -- -- Start tbody for this group
        lc_html := lc_html || '<tbody><tr>';

        -- Add images for this group
        for k in i..least(i + lv_const_col_cnt - 1, lt_docs.count) loop
            -- lc_html := lc_html || '<td style="width:200px;height:300px;border:none;">'
            --                     || '<img src="data:image/jpeg;base64,' || lt_docs(k).img_data || '" '
            --                     || 'style="width:300px;height:300px;object-fit:contain;display:block;">'
            --                     || '</td>';
            dbms_lob.append(lc_html,
                '<td style="width:200px;height:300px;border:none;">'
                || '<img src="data:image/jpeg;base64,' || lt_docs(k).img_data || '" '
                || 'style="width:300px;height:300px;object-fit:contain;display:block;">'
                || '</td>'
            );
        end loop;

        lc_html := lc_html || '</tr></tbody>';
        end loop;

        lc_html := lc_html || '</table>';



        print_clob(lc_html);


        return lc_html;

    exception
        when others then
            close c_get_docs;
    end;
end icca_aop_pdf;