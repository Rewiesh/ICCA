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

        lv_img_based64 clob := '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
XGL6hA+iAAAAAElFTkSuQmCC';

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

        /* Create main table */
        lc_html := '<table style="width: 100%; text-align: center; border-collapse: separate; border-spacing: 40px 10px;">';
        for i in 1..lt_docs.count by lv_const_col_cnt loop

          dbms_lob.append(lc_html, '<thead><tr style="padding:10px 30px;">');

            for j in i..least(i + lv_const_col_cnt  - 1, lt_docs.count) loop
               dbms_lob.append(lc_html,
                            '<th style="padding: 10px; border:1px solid red;">'
                            -- '<th style="padding: 10px; border:none;">'
                        ||      '<b>Foto' || lt_docs(j).rn ||'</b>'
                        ||  '</th>'
               )
                        ;
                -- Append empty table headers for spacing, note that this is done between the 1st, 2nd and 3rd image
                if j < least(i + lv_const_col_cnt - 1, lt_docs.count) then
                    dbms_lob.append(lc_html,
                                '<th style="width:20px; border:none;"></th>'
                                    );
                end if;

            end loop;

            dbms_lob.append(lc_html,  '</tr></thead>');
            -- dbms_lob.append(lc_html, '</tr><tr><td colspan="'|| to_char((lv_const_col_cnt*2-1)) ||'" style="height:20px; border:1px solid blue;"></td></tr></thead>');


            -- -- Start tbody for this group
            lc_html := lc_html || '<tbody><tr>';

            -- Add images for this group
            for k in i..least(i + lv_const_col_cnt - 1, lt_docs.count) loop
                dbms_lob.append(lc_html,
                    --    '<td style="width:200px; height:300px; border:3px solid green; vertical-align:middle;">'
                    '<td style="width:300px; height:400px; border:none;">'
                    || '<img src="data:image/'|| lt_docs(k).mime_type || ';base64,' || lt_docs(k).img_data || '" ' --* actual image
                    -- || '<img src="data:image/'|| lt_docs(k).mime_type || ';base64,' || 'lv_img_based64' || '" ' --* for logging html
                    -- || '<img src="data:image/'|| lt_docs(k).mime_type || ';base64,' || lv_img_based64 || '" '   --* for testing img ==> SR LOGO
                    || 'style="width:auto; height:auto; object-fit:contain; display:block;">'
                    || '</td>'
                );

                -- Append empty table headers for spacing, note that this is done between the 1st, 2nd and 3rd image
                if k < least(i + lv_const_col_cnt - 1, lt_docs.count) then
                    dbms_lob.append(lc_html,
                                -- '<td style="border:1px solid blue"></td>'
                                '<td style="border:none"></td>'
                                    );
                end if;
            end loop;

            dbms_lob.append(lc_html, '<tr style="height:100px; border:2px solid yellow;><td colspan="'|| to_char((lv_const_col_cnt*2-1)) ||'" style="height:10px; border:1px solid blue;"></td></tr>');
            dbms_lob.append(lc_html, '</tr></tbody>');
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