create or replace package body icca_kwaliteits_meting_pdf_template
is
    --
    -- global variables
    --
    gv_pdf_color_restitutie constant varchar2(6)    := '000000';
    gv_vb_color             constant varchar2(6)    := '000000'; 
    gv_hulp_lijnen          constant varchar2(6)    := 'FFFFFF'; 
    --
    -- global pdf blob
    --
    gb_pdf                  blob;
    --
    --------------------------------------------------------------------------------------------------
    --
    --  Document Header te bouwen van blad 1 met foto
    --
    procedure p_build_foto_header (  p_format in varchar2 default 'A4') 
    is
        --
        -- Variables
        --
        l_width                  number := 595; 
        l_height                 number := 842; 
        l_margin_x               number := 29; 
        l_topright_textbox_start number := 0;
        l_topright_textbox_width number := 0;
        l_offset_y               number := 0;
        l_image                  blob;
        --
        --
    begin
        --
        as_pdf3.set_page_format(p_format);
        --
        -- Tijdelijke om me foto op te halen ( Dit dmv een systeem_parameter doen)
        --
        select chart_image	
        into   l_image
        from   chart_images	
        where  image_id = 146
        order by image_id desc
        fetch first 1 row only;
        --
        -- Tijdelijke om me foto te tonen ( Dimension moet 817 x 225)
        --        
        as_pdf3.put_image( p_img => l_image
                        , p_x       => 0
                        , p_y       => 640
                        , p_width   => 595
                        , p_height  => 1000
                        , p_align   => 'start'
                        , p_valign  => 'top'
                        );
        --
        -- Me lijn waar er rapportage test kwaliteitsmeting wordt geplaatst en met de kleur Blauw
        --                
        as_pdf3.vertical_line(    p_x           => 210
                                , p_y           => 580
                                , p_height      => 80
                                , p_line_width  => 400
                                , p_line_color  => '4682b4'
                                );
        --
        -- Zet me kleur naar wit voor me data
        --                                
        as_pdf3.set_color( p_rgb => 'Ffffff'); 
        --
        -- Bepaal me lettertype config
        --
        as_pdf3.set_font( p_family      => 'helvetica'
                        , p_style       =>  'N'
                        , p_fontsize_pt =>  22
                        );
        --
        -- Label rapportage
        --
        as_pdf3.write(  p_txt => 'Rapportage'
                      , p_x   => 20
                      , p_y   => 630);
        --
        -- Label test kwaliteitsmeting
        --
        as_pdf3.write(  p_txt => 'TEST Kwaliteitsmeting'
                      , p_x   => 20
                      , p_y   => 600);
        --
        --                                                                
    end p_build_foto_header;
    --
    --------------------------------------------------------------------------------------------------
    --
    -- Footer van de document te bouwen
    --
    procedure p_build_footer (  p_format                     in varchar2 default 'A4'
                             ,  p_kwaliteits_meeting_values  t_kwaliteits_meeting_values
                             ) 
    is
        --
        -- Variables
        --
        l_ratio_x       number;
        l_ratio_y       number;
        l_ratio         number;
        l_width         number := 595; 
        l_height        number := 842; 
        l_margin_x      number := 29; 
        ln_x            number := 0;
        ln_y            number := 0;
        ln_fil_line     number := 0;
        ln_max_leng_col number := 0;
        ln_orientatie   varchar2(100) := 'PORTRAIT';
        --
        --
    begin
        --
        -- Zet de formaat van de pagina 
        as_pdf3.set_page_format(p_format);
        --
        -- Zet de orientatie van de pagina
        --
        as_pdf3.set_page_orientation(ln_orientatie);
        --
        -- Bepaal de ratio op basis van je pagina formaat
        --
        if p_format = 'A4' 
        then
            l_ratio := 1;
        elsif p_format = 'A5' 
        then
          l_ratio := ( 1 / 1.41421 );
        elsif p_format = 'A3' 
        then
          l_ratio := 1.41421;
        end if;
        --
        -- Bepaal de waardes van me variables op basis van me orientatie
        --
        if ln_orientatie = 'PORTRAIT' 
        then
            l_ratio_x  := l_ratio;
            l_ratio_y  := l_ratio;
            l_width    := l_width * l_ratio_x;
            l_height   := l_height * l_ratio_y;
            l_margin_x := l_margin_x * l_ratio_x;
        elsif ln_orientatie = 'LANDSCAPE' 
        then
          l_ratio_x  := l_ratio * 1.41421;
          l_ratio_y  := l_ratio / 1.41421;
          l_width    := l_width * l_ratio_x;
          l_height   := l_height * l_ratio_y;
          l_margin_x := l_margin_x * l_ratio_x;
        end if;
        --
        -- Set margins for the page
        --
        as_pdf3.set_margins(p_top => 0.01, p_left => 0.01, p_bottom => 0.01, p_right => 0.01);
        --        
        -- Zet me footer blauw lijn
        --
        as_pdf3.vertical_line(    p_x           => 295
                                , p_y           => 40
                                , p_height      => 22
                                , p_line_width  => 540
                                , p_line_color  => '4682b4'
                                );
        --                                
        -- Zet me kleur naar Wit
        --                                
        as_pdf3.set_color( p_rgb => 'Ffffff');
        --                         
        -- Zet me lettertype config
        --
        as_pdf3.set_font( p_family    => 'helvetica'
                        , p_style       =>  'N'
                        , p_fontsize_pt =>  12
                        );
        --                
        -- Label Datum
        --                
        as_pdf3.write(  p_txt => 'Datum:'
                      , p_x   => 40
                      , p_y   => 45);
        --                
        -- Value Datum
        --                
        as_pdf3.write(  p_txt => '29 december 2017'
                      , p_x   => 82
                      , p_y   => 45);
        --
        --                                                                
    end p_build_footer; 
--------------------------------------------------------------------------------------------------
    --
    -- Header van de document te bouwen voor alle pagina's behalve pagina 1
    --
    procedure p_build_header (  p_format                     in varchar2 default 'A4'
                             ,  p_kwaliteits_meeting_values  t_kwaliteits_meeting_values
                             ) 
    is
        --
        -- Variables
        --
        l_ratio_x       number;
        l_ratio_y       number;
        l_ratio         number;
        l_width         number := 595; 
        l_height        number := 842; 
        l_margin_x      number := 29; 
        ln_x            number := 0;
        ln_y            number := 0;
        ln_fil_line     number := 0;
        ln_max_leng_col number := 0;
        ln_orientatie   varchar2(100) := 'PORTRAIT';
        --
        --
    begin
        --
        -- Zet de formaat van de pagina 
        as_pdf3.set_page_format(p_format);
        --
        -- Zet de orientatie van de pagina
        --
        as_pdf3.set_page_orientation(ln_orientatie);
        --
        -- Bepaal de ratio op basis van je pagina formaat
        --
        if p_format = 'A4' 
        then
            l_ratio := 1;
        elsif p_format = 'A5' 
        then
          l_ratio := ( 1 / 1.41421 );
        elsif p_format = 'A3' 
        then
          l_ratio := 1.41421;
        end if;
        --
        -- Bepaal de waardes van me variables op basis van me orientatie
        --
        if ln_orientatie = 'PORTRAIT' 
        then
            --
            l_ratio_x   := l_ratio;
            l_ratio_y   := l_ratio;
            l_width     := l_width * l_ratio_x;
            l_height    := l_height * l_ratio_y;
            l_margin_x  := l_margin_x * l_ratio_x;
            --
        elsif ln_orientatie = 'LANDSCAPE' 
        then
            --
            l_ratio_x     := l_ratio * 1.41421;
            l_ratio_y     := l_ratio / 1.41421;
            l_width       := l_width * l_ratio_x;
            l_height      := l_height * l_ratio_y;
            l_margin_x    := l_margin_x * l_ratio_x;
            --
        end if;
        --
        -- Set margins for the page
        --
        as_pdf3.set_margins(p_top => 0.01, p_left => 0.01, p_bottom => 0.01, p_right => 0.01);
        --        
        -- Zet me footer blauw lijn
        --
        as_pdf3.vertical_line(    p_x           => 295
                                , p_y           => 800
                                , p_height      => 22
                                , p_line_width  => 540
                                , p_line_color  => '4682b4'
                                );
        --                                
        -- Zet me kleur naar Wit
        --                                
        as_pdf3.set_color( p_rgb => 'Ffffff');
        --                         
        -- Zet me lettertype config
        --
        as_pdf3.set_font( p_family    => 'helvetica'
                        , p_style       =>  'N'
                        , p_fontsize_pt =>  12
                        );
        --                
        -- Label Project
        --                
        as_pdf3.write(  p_txt => 'Project:'
                      , p_x   => 40
                      , p_y   => 805);
        --              
        -- Value Project
        --
        as_pdf3.write(  p_txt => 'LocatieAAB'
                      , p_x   => 85
                      , p_y   => 805);                              
        --                
        -- Label Rapportnummer
        --                
        as_pdf3.write(  p_txt => 'Rapportnummer:'
                      , p_x   => 415
                      , p_y   => 805);
        --                
        -- Value Rapportnummer
        --                
        as_pdf3.write(  p_txt => p_kwaliteits_meeting_values.rapport_nummer
                      , p_x   => 510
                      , p_y   => 805);
        --                      
        --
        --                                                                
    end p_build_header;           
    --------------------------------------------------------------------------------------------------
    --
    --  ** build kwaliteits meeting pdf **
    --
    procedure p_build_kwaliteits_meting_pdf (   p_kwaliteits_meeting_values  t_kwaliteits_meeting_values
                                            ) 
    is
        --
        -- build kwaliteits meeting pdf body
        --
        procedure p_build_kwaliteits_meting_body (  p_kwaliteits_meeting_values  t_kwaliteits_meeting_values
                                                 ) 
        is
            --
            -- Variables algemeent       
            l_image_bar_line    blob;
            l_image_donut       blob;
            --
            -- DJ Grafief values berekening variables
            --
            l_up_down_blok1    number := 0 ;
            l_up_down_blok2    number := 0 ;
            l_up_down_blok3    number := 0 ;
            l_up_down_blok4    number := 0 ;
            l_up_down_blok5    number := 0 ;
            l_up_down_blok6    number := 0 ;  
            l_up_down_blok7    number := 0 ;
            l_up_down_blok8    number := 0 ;
            l_up_down_blok9    number := 0 ;                                                   
        begin
            --
            -- Bepaal me lettertype config
            --
            as_pdf3.set_font(p_family => 'times', p_style => 'N', p_fontsize_pt => 14);
            --
            -- Kleur Grijs voor pagina 1
            --
            as_pdf3.set_color( p_rgb => '808080');
            --
            -- Page 1
            --
            -- Label Organisatie
            --
            as_pdf3.write(  p_txt => 'Organisatie:'
                          , p_x   => 40
                          , p_y   => 525);
            --
            -- Value  Organisatie
            --
            as_pdf3.write(  p_txt => 'Test Company'
                          , p_x   => 40
                          , p_y   => 510);
            --
            -- Label Ter attentie van
            --
            as_pdf3.write(  p_txt => 'Ter attentie van:'
                          , p_x   => 40
                          , p_y   => 480);
            --
            -- Value  Ter attentie van
            --
            as_pdf3.write(  p_txt => 'Anjali Badal'
                          , p_x   => 40
                          , p_y   => 465);
            --
            -- Label project 
            --
            as_pdf3.write(  p_txt => 'Project'
                          , p_x   => 40
                          , p_y   => 435);
            --
            -- Label :
            --
            as_pdf3.write(  p_txt => ':'
                          , p_x   => 160
                          , p_y   => 435);
            --
            -- Value project
            --
            as_pdf3.write(  p_txt => 'LocatieAAB'
                          , p_x   => 185
                          , p_y   => 435);                          

            --
            -- Label Rapportnummer 
            --
            as_pdf3.write(  p_txt => 'Rapportnummer'
                          , p_x   => 40
                          , p_y   => 420);
            -- Label :
            --
            as_pdf3.write(  p_txt => ':'
                          , p_x   => 160
                          , p_y   => 420);                          
            --
            -- Value Rapportnummer
            --
            as_pdf3.write(  p_txt => p_kwaliteits_meeting_values.rapport_nummer
                          , p_x   => 185
                          , p_y   => 420); 
            --
            -- Label Datum 
            --
            as_pdf3.write(  p_txt => 'Datum'
                          , p_x   => 40
                          , p_y   => 390);
            -- Label :
            --
            as_pdf3.write(  p_txt => ':'
                          , p_x   => 160
                          , p_y   => 390);                          
            --
            -- Value Datum
            --
            as_pdf3.write(  p_txt => '29 december 2017'
                          , p_x   => 185
                          , p_y   => 390); 
            --                          
            -- Label Tijdstop controle 
            --
            as_pdf3.write(  p_txt => 'Tijdstop controle'
                          , p_x   => 40
                          , p_y   => 375);
            -- Label :
            --
            as_pdf3.write(  p_txt => ':'
                          , p_x   => 160
                          , p_y   => 375);                          
            --
            -- Value Tijdstop controle
            --
            as_pdf3.write(  p_txt => '14:35'
                          , p_x   => 185
                          , p_y   => 375); 
            --                
            -- Label -
            --
            as_pdf3.write(  p_txt => '-'
                          , p_x   => 40
                          , p_y   => 325); 
            --              
            -- Label Controle door wie
            --
            as_pdf3.write(  p_txt => 'Controle uitgevoerd door:'
                          , p_x   => 40
                          , p_y   => 295);
            --
            -- Value  Controle door wie
            --
            as_pdf3.write(  p_txt => 'Anjali'
                          , p_x   => 40
                          , p_y   => 280);  
            --              
            -- Label leverancier aanwezig
            --
            as_pdf3.write(  p_txt => 'Aanwezig leverancier'
                          , p_x   => 40
                          , p_y   => 250);
            --
            -- Value  Controle door wie
            --
            as_pdf3.write(  p_txt => 'n.v.t'
                          , p_x   => 40
                          , p_y   => 235);  

            --                          
            -- Zet me footer voor pagina 1
            --
            p_build_footer( p_format                    => 'A4'
                         ,  p_kwaliteits_meeting_values => p_kwaliteits_meeting_values
                         );
            --
            -- Page 2
            -- Voeg een nieuw pagina toe
            --
            as_pdf3.new_page;
            --
            -- Kleur Grijs voor pagina 2 labels en values
            --
            as_pdf3.set_color( p_rgb => '808080');            
            --
            -- Bepaal me lettertype config
            --
            as_pdf3.set_font(p_family => 'times', p_style => 'N', p_fontsize_pt => 13);
            --
            -- Label geachte  
            --
            as_pdf3.write(  p_txt => 'Geachte heer, mevrouw,'
                          , p_x   => 40
                          , p_y   => 700); 
            --                 
            -- Value datum & locatie zin ( 1ste zin na geachte heer,mevrouw)  
            --
            as_pdf3.write(  p_txt => 'Op 29 december 2017 is in locatie AAB gelegen aan de LocatieA te LocatieA, de uitvoering van'
                          , p_x   => 40
                          , p_y   => 670); 
            --
            -- Label Alinea 2 Regel 1  
            --
            as_pdf3.write(  p_txt => 'Naar aanleiding van deze uitgevoerde controle zenden wij u hierbij de rapportage waarin de'
                          , p_x   => 40
                          , p_y   => 640);  
            --              
            -- Label Alinea 2 Regel 2   
            --
            as_pdf3.write(  p_txt => 'bevinden zijn weergegeven. Voor uitleg omtrent het resultaat van onze rapportage kunt u contact'
                          , p_x   => 40
                          , p_y   => 625);  
            --              
            -- Label Alinea 2 Regel 3   
            --
            as_pdf3.write(  p_txt => 'met ons opnemen.'
                          , p_x   => 40
                          , p_y   => 610);
            --              
            -- Label Alinea 3 Regel 1   
            --
            as_pdf3.write(  p_txt => 'Wij vertrouwen erop u hiermee voldoende te hebben geïnformeerd.'
                          , p_x   => 40
                          , p_y   => 580);
            --               
            -- Label Alinea 4 Regel 1   
            --
            as_pdf3.write(  p_txt => 'Met vriendelijke groet,'
                          , p_x   => 40
                          , p_y   => 550);
            --               
            -- Label Alinea 5 Regel 1   
            --
            as_pdf3.write(  p_txt => 'Het Kwaliteitsteam'
                          , p_x   => 40
                          , p_y   => 520);                                                                                                                                                                                                 
            --            
            -- Zet me header voor pagina 2
            --
            p_build_header( p_format                    => 'A4'
                         ,  p_kwaliteits_meeting_values => p_kwaliteits_meeting_values
                         );
            --             
            -- Zet me footer voor pagina 2
            --
            p_build_footer( p_format                    => 'A4'
                         ,  p_kwaliteits_meeting_values => p_kwaliteits_meeting_values
                         );
               
            -- 
            -- Page 3 := Grafieken Pagina
            -- Voeg een nieuw pagina toe
            --
            as_pdf3.new_page;
            --
            -- Kleur Zwart voor label resultaten van de controle
            --
            as_pdf3.set_color( p_rgb => '000000');            
            --
            -- Bepaal me lettertype config
            --
            as_pdf3.set_font(p_family => 'times', p_style => 'B', p_fontsize_pt => 18);
            --
            -- Label resultaten van de controle
            --
            as_pdf3.write(  p_txt => 'Resultaten van de controle'
                          , p_x   => 40
                          , p_y   => 750); 
            -- Bepaal me lettertype config
            --
            as_pdf3.set_font(p_family => 'times', p_style => 'N', p_fontsize_pt => 13);
            --
            -- Kleur Grijs voor pagina 2 labels en values
            --
            as_pdf3.set_color( p_rgb => '808080');             
            --
            --Label project page 3
            --
            as_pdf3.write(  p_txt => 'Project:'
                          , p_x   => 87
                          , p_y   => 715); 
            --
            -- Label rapportnummer page 3
            --
            as_pdf3.write(  p_txt => 'Rapportnummer:'
                          , p_x   => 40
                          , p_y   => 700); 
            --
            -- Label historisch verloop page 3
            --
            as_pdf3.write(  p_txt => 'Historisch verloop'
                          , p_x   => 400
                          , p_y   => 700); 
            --              
            -- Label verhouding dagelijkse-/ en cumaltieve foutsoorten page 3
            --
            as_pdf3.write(  p_txt => 'Verhouding'
                          , p_x   => 360
                          , p_y   => 415); 
            --
            -- label dagelijkse-/ en cumulatieve foutsoorten
            --               
            as_pdf3.write(  p_txt => 'Dagelijkse-/ en cumulatieve foutsoorten'
                          , p_x   => 360
                          , p_y   => 400); 
            --
            -- label Aantal foutsoorten
            --               
            as_pdf3.write(  p_txt => 'Aantal foutsoorten'
                          , p_x   => 30
                          , p_y   => 414); 
            --
            -- Value controle datum
            --               
            as_pdf3.write(  p_txt => 'Controle 29 december 2017'
                          , p_x   => 30
                          , p_y   => 400); 
            --                                
            -- Zet me kleur naar Wit voor me DJ grafiek values
            --                                
            as_pdf3.set_color( p_rgb => 'Ffffff');   --Ffffff   
            --
            -- Bepaal me lettertype config
            --
            as_pdf3.set_font(p_family => 'times', p_style => 'N', p_fontsize_pt => 11);                                     
            --              
            -- Grafiek DJ set Lijn 1 'Niet gehecht vuil licht stof'
            -- 
            as_pdf3.vertical_line(    p_x           => 40
                                    , p_y           => 250
                                    , p_height      => 120
                                    , p_line_width  => 2.2
                                    , p_line_color  => '808080'
                                    );
            --
            -- Blok 1
            --                                    
            as_pdf3.vertical_line(    p_x           => 40
                                    , p_y           => 250
                                    , p_height      => 20
                                    , p_line_width  => 20
                                    , p_line_color  => '9ACD32'
                                    ); 
            --
            -- Label blok 'Niet gehecht vuil licht stof'
            --                                    
            as_pdf3.vertical_line(    p_x           => 38
                                    , p_y           => 205
                                    , p_height      => 40
                                    , p_line_width  => 30
                                    , p_line_color  => '9ACD32'
                                    ); 
            --                        
            -- Value Blok 1
            --                        
            as_pdf3.write(  p_txt   => '0'
                          , p_x     => 37
                          , p_y     => 255
                          );                                     

            --              
            -- Grafiek DJ set Lijn 2 'Niet gehecht vuil licht Methode'
            -- 
            as_pdf3.vertical_line(    p_x           => 70
                                    , p_y           => 250
                                    , p_height      => 120
                                    , p_line_width  => 2.2
                                    , p_line_color  => '808080'
                                    );
            if 1 = 1
            then 
                l_up_down_blok2 := 60;
            else 
                l_up_down_blok2 := 0;    
            end if;                                     
            --
            -- Blok 2
            --                                    
            as_pdf3.vertical_line(    p_x           => 70
                                    , p_y           => 250 + l_up_down_blok2
                                    , p_height      => 20
                                    , p_line_width  => 20
                                    , p_line_color  => '9ACD32'
                                    );
            --                        
            -- Value Blok 2                        
            --
            as_pdf3.write(  p_txt   => '2'
                          , p_x     => 67
                          , p_y     => 255 + l_up_down_blok2
                          );                                        
            --
            -- Label blok 'Niet gehecht vuil licht Methode'
            --                                    
            as_pdf3.vertical_line(    p_x           => 70
                                    , p_y           => 205
                                    , p_height      => 40
                                    , p_line_width  => 30
                                    , p_line_color  => '9ACD32'
                                    );

                                                                         
            --              
            -- Grafiek DJ set Lijn 3 'Aanslag'
            -- 
            as_pdf3.vertical_line(    p_x           => 100
                                    , p_y           => 250
                                    , p_height      => 120
                                    , p_line_width  => 2.2
                                    , p_line_color  => '808080'
                                    );
            --
            -- Blok 3
            --                                    
            as_pdf3.vertical_line(    p_x           => 100
                                    , p_y           => 250
                                    , p_height      => 20
                                    , p_line_width  => 20
                                    , p_line_color  => '4682B4'
                                    ); 
            --                        
            -- Value Blok 3                        
            --
            as_pdf3.write(  p_txt   => '0'
                          , p_x     => 98
                          , p_y     => 255
                          );                                       
            --
            -- Label blok 'Aanslag'
            --                                    
            as_pdf3.vertical_line(    p_x           => 102
                                    , p_y           => 205
                                    , p_height      => 40
                                    , p_line_width  => 30
                                    , p_line_color  => '4682B4'
                                    );
                                                                        
            --              
            -- Grafiek DJ set Lijn 4 'Dicht stof'
            -- 
            as_pdf3.vertical_line(    p_x           => 135
                                    , p_y           => 250
                                    , p_height      => 120
                                    , p_line_width  => 2.2
                                    , p_line_color  => '808080'
                                    );
            --
            -- Blok 4
            --                                    
            as_pdf3.vertical_line(    p_x           => 135
                                    , p_y           => 250
                                    , p_height      => 20
                                    , p_line_width  => 20
                                    , p_line_color  => '4682B4'
                                    ); 
            --                        
            -- Value Blok 4                        
            --
            as_pdf3.write(  p_txt   => '0'
                          , p_x     => 130
                          , p_y     => 255
                          );                                       
            --
            -- Label blok 'Dicht stof'
            --                                    
            as_pdf3.vertical_line(    p_x           => 134
                                    , p_y           => 205
                                    , p_height      => 40
                                    , p_line_width  => 30
                                    , p_line_color  => '4682B4'
                                    );  
                                                                        
            --              
            -- Grafiek DJ set Lijn 5 'Gehecht vuil methode'
            -- 
            as_pdf3.vertical_line(    p_x           => 165
                                    , p_y           => 250
                                    , p_height      => 120
                                    , p_line_width  => 2.2
                                    , p_line_color  => '808080'
                                    );
            --
            -- Blok 5
            --                                    
            as_pdf3.vertical_line(    p_x           => 165
                                    , p_y           => 250
                                    , p_height      => 20
                                    , p_line_width  => 20
                                    , p_line_color  => '4682B4'
                                    ); 
            --                        
            -- Value Blok 5                        
            --
            as_pdf3.write(  p_txt   => '0'
                          , p_x     => 162
                          , p_y     => 255
                          );                                      
            --
            -- Label blok 'Gehecht vuil methode'
            --                                    
            as_pdf3.vertical_line(    p_x           => 166
                                    , p_y           => 205
                                    , p_height      => 40
                                    , p_line_width  => 30
                                    , p_line_color  => '4682B4'
                                    ); 
                                                                          
            --              
            -- Grafiek DJ set Lijn 6 'Gehecht vuil vlek vingertas'
            -- 
            as_pdf3.vertical_line(    p_x           => 195
                                    , p_y           => 250
                                    , p_height      => 120
                                    , p_line_width  => 2.2
                                    , p_line_color  => '808080'
                                    );
            --
            -- Blok 6
            --                                    
            as_pdf3.vertical_line(    p_x           => 195
                                    , p_y           => 250
                                    , p_height      => 20
                                    , p_line_width  => 20
                                    , p_line_color  => '4682B4'
                                    );
            --                        
            -- Value Blok 6                        
            --
            as_pdf3.write(  p_txt   => '0'
                          , p_x     => 190
                          , p_y     => 255
                          );                                       
            --
            -- Label blok 'Gehecht vuil vlek vingertas'
            --                                    
            as_pdf3.vertical_line(    p_x           => 198
                                    , p_y           => 205
                                    , p_height      => 40
                                    , p_line_width  => 30
                                    , p_line_color  => '4682B4'
                                    ); 
                                                                           
            --              
            -- Grafiek DJ set Lijn 7 'Niet aangevuld'
            -- 
            as_pdf3.vertical_line(    p_x           => 230
                                    , p_y           => 250
                                    , p_height      => 120
                                    , p_line_width  => 2.2
                                    , p_line_color  => '808080'
                                    );
            --
            -- Blok 7
            --                                    
            as_pdf3.vertical_line(    p_x           => 230
                                    , p_y           => 250
                                    , p_height      => 20
                                    , p_line_width  => 20
                                    , p_line_color  => 'D2B48C'
                                    );
            --                        
            -- Value Blok 7                        
            --
            as_pdf3.write(  p_txt   => '0'
                          , p_x     => 227
                          , p_y     => 255
                          );                                        
            --
            -- Label blok 'Niet aangevuld'
            --                                    
            as_pdf3.vertical_line(    p_x           => 230
                                    , p_y           => 205
                                    , p_height      => 40
                                    , p_line_width  => 30
                                    , p_line_color  => 'D2B48C'
                                    );
            --              
            -- Grafiek DJ set Lijn 8 'Niet geleegd'
            -- 
            as_pdf3.vertical_line(    p_x           => 260
                                    , p_y           => 250
                                    , p_height      => 120
                                    , p_line_width  => 2.2
                                    , p_line_color  => '808080'
                                    );
            --
            -- Blok 8
            --                                    
            as_pdf3.vertical_line(    p_x           => 260
                                    , p_y           => 250
                                    , p_height      => 20
                                    , p_line_width  => 20
                                    , p_line_color  => 'D2B48C'
                                    );
            --                        
            -- Value Blok 8                        
            --
            as_pdf3.write(  p_txt   => '0'
                          , p_x     => 255
                          , p_y     => 255
                          );                                       
            --
            -- Label blok 'Niet geleegd'
            --                                    
            as_pdf3.vertical_line(    p_x           => 262
                                    , p_y           => 205
                                    , p_height      => 40
                                    , p_line_width  => 30
                                    , p_line_color  => 'D2B48C'
                                    );
                                                                            
            --              
            -- Grafiek DJ set Lijn 9 'Spinrag'
            -- 
            as_pdf3.vertical_line(    p_x           => 290
                                    , p_y           => 250
                                    , p_height      => 120
                                    , p_line_width  => 2.2
                                    , p_line_color  => '808080'
                                    );
            --
            -- Blok 9
            --                                    
            as_pdf3.vertical_line(    p_x           => 290
                                    , p_y           => 250
                                    , p_height      => 20
                                    , p_line_width  => 20
                                    , p_line_color  => 'D2B48C'
                                    );
            --                        
            -- Value Blok 9                        
            --
            as_pdf3.write(  p_txt   => '0'
                          , p_x     => 285
                          , p_y     => 255
                          );                                     
            --
            -- Label blok 'Spinrag'
            --                                    
            as_pdf3.vertical_line(    p_x           => 294
                                    , p_y           => 205
                                    , p_height      => 40
                                    , p_line_width  => 30
                                    , p_line_color  => 'D2B48C'
                                    );                                                                                                                                                                                                                                                                                                      
            --                                
            -- Zet me kleur naar Wit voor me DJ grafiek values
            --                                
            as_pdf3.set_color( p_rgb => 'Ffffff');   --Ffffff
            --
            -- Bepaal me lettertype config
            --
            as_pdf3.set_font(p_family => 'times', p_style => 'N', p_fontsize_pt => 7);  
            --
            -- Label Lijn 1 'Niet gehecht vuil licht stof'
            --
            as_pdf3.write(  p_txt   => 'Niet gehecht vuil licht stof'
                          , p_x     => 25
                          , p_start => 25
                          , p_y     => 235
                          , p_width => 30); 
            --
            -- Label Lijn 2 'Niet gehecht vuil licht methode'
            --
            as_pdf3.write(  p_txt   => 'Niet gehecht vuil methode'
                          , p_x     => 58
                          , p_start => 58
                          , p_y     => 235
                          , p_width => 30);  
            --
            -- Label Lijn 3 'Aanslag''
            --
            as_pdf3.write(  p_txt   => 'Aanslag'
                          , p_x     => 91
                          , p_start => 91
                          , p_y     => 220
                          , p_width => 30);  
            --
            -- Label Lijn 4 'Dicht stof'
            --
            as_pdf3.write(  p_txt   => 'Dicht stof'
                          , p_x     => 120
                          , p_start => 120
                          , p_y     => 220
                          , p_width => 30);  
            --
            -- Label Lijn 5 'Gehecht vuil methode'
            --
            as_pdf3.write(  p_txt   => 'Gehecht vuil methode'
                          , p_x     => 153
                          , p_start => 153
                          , p_y     => 230
                          , p_width => 35); 
            --
            -- Label Lijn 6 'Gehecht vuil methode'
            --
            as_pdf3.write(  p_txt   => 'Gehecht vuil vlek vingertast'
                          , p_x     => 185
                          , p_start => 185
                          , p_y     => 230
                          , p_width => 35); 
            --
            -- Label Lijn 7 'Niet aangevuld'
            --
            as_pdf3.write(  p_txt   => 'Niet aangevuld'
                          , p_x     => 216
                          , p_start => 216
                          , p_y     => 225
                          , p_width => 30);   
            --
            -- Label Lijn 8 'Niet geleegd'
            --
            as_pdf3.write(  p_txt   => 'Niet geleegd'
                          , p_x     => 250
                          , p_start => 250
                          , p_y     => 225
                          , p_width => 30);   
            --
            -- Label Lijn 9 'Spinrag'
            --
            as_pdf3.write(  p_txt   => 'Spinrag'
                          , p_x     => 282
                          , p_start => 282
                          , p_y     => 225
                          , p_width => 30);
            --
            -- Donut blok dagelijkse 
            --                  
            as_pdf3.vertical_line(    p_x           => 370
                                    , p_y           => 240
                                    , p_height      => 40
                                    , p_line_width  => 50
                                    , p_line_color  => '9ACD32'
                                    );  
            --
            -- Blok cumulatief 
            --                  
            as_pdf3.vertical_line(    p_x           => 430
                                    , p_y           => 240
                                    , p_height      => 40
                                    , p_line_width  => 50
                                    , p_line_color  => '4682B4'
                                    );
            --                        
            -- Blok Diverse 
            --                  
            as_pdf3.vertical_line(    p_x           => 490
                                    , p_y           => 240
                                    , p_height      => 40
                                    , p_line_width  => 50
                                    , p_line_color  => 'D2B48C'
                                    );
            --
            -- Labels Donut
            --                         
            as_pdf3.write(  p_txt   => 'Dagelijks'
                          , p_x     => 355
                          , p_y     => 260
                          ); 
            --
            -- Label Cumulatief
            --              
            as_pdf3.write(  p_txt   => 'Cumulatief'
                          , p_x     => 415
                          , p_y     => 260
                          ); 
            --
            -- Label Diverse
            --              
            as_pdf3.write(  p_txt   => 'Diverse'
                          , p_x     => 480
                          , p_y     => 260
                          );
            --
            -- Tabel  Lange lijn 1ste 
            --                  
            as_pdf3.vertical_line(    p_x           => 280
                                    , p_y           => 190
                                    , p_height      => 2
                                    , p_line_width  => 510
                                    , p_line_color  => '9ACD32'
                                    );
            --
            -- Begin vertical 
            --                       
            as_pdf3.vertical_line(    p_x           => 25
                                    , p_y           => 150
                                    , p_height      => 42
                                    , p_line_width  => 2
                                    , p_line_color  => '9ACD32'
                                    );
            --
            -- Laatste vertical
            --                        
            as_pdf3.vertical_line(    p_x           => 535
                                    , p_y           => 150
                                    , p_height      => 42
                                    , p_line_width  => 2
                                    , p_line_color  => '9ACD32'
                                    );                                    
            --
            --   2de lijn lange grijse
            --                     
            as_pdf3.vertical_line(    p_x           => 280
                                    , p_y           => 170
                                    , p_height      => 2
                                    , p_line_width  => 510
                                    , p_line_color  => '808080'
                                    ); 
            --
            -- laatste lijn
            --                        
            as_pdf3.vertical_line(    p_x           => 280
                                    , p_y           => 150
                                    , p_height      => 2
                                    , p_line_width  => 510
                                    , p_line_color  => '9ACD32'
                                    );
            --
            -- Tussen vertical 1ste
            --                        
            as_pdf3.vertical_line(    p_x           => 120
                                    , p_y           => 150
                                    , p_height      => 42
                                    , p_line_width  => 2
                                    , p_line_color  => '808080'
                                    );   
            --
            -- Tussen vertical 2de
            --                        
            as_pdf3.vertical_line(    p_x           => 260
                                    , p_y           => 150
                                    , p_height      => 42
                                    , p_line_width  => 2
                                    , p_line_color  => '808080'
                                    );
            --
            -- Tussen vertical 3de
            --                        
            as_pdf3.vertical_line(    p_x           => 350
                                    , p_y           => 150
                                    , p_height      => 42
                                    , p_line_width  => 2
                                    , p_line_color  => '808080'
                                    );  
            --
            -- Tussen vertical 4de
            --                        
            as_pdf3.vertical_line(    p_x           => 465
                                    , p_y           => 150
                                    , p_height      => 42
                                    , p_line_width  => 2
                                    , p_line_color  => '808080'
                                    );                                                                                                                                                    
            --                                
            -- Zet me kleur naar Zwart voor me tabel
            --                                
            as_pdf3.set_color( p_rgb => '000000');   --Ffffff
            --
            -- Bepaal me lettertype config
            --
            as_pdf3.set_font(p_family => 'times', p_style => 'B', p_fontsize_pt => 10);                                   
            --
            -- Label Categorie
            --              
            as_pdf3.write(  p_txt   => 'Categorie'
                          , p_x     => 28
                          , p_y     => 180
                          ); 
            --
            -- Label Tel-element
            --              
            as_pdf3.write(  p_txt   => 'Tel-element'
                          , p_x     => 160
                          , p_y     => 180
                          );
            --
            -- Label Goedkeurgrens
            --              
            as_pdf3.write(  p_txt   => 'Goedkeurgrens'
                          , p_x     => 270
                          , p_y     => 180
                          );
            --
            -- Label Aantal behaalde fouten
            --              
            as_pdf3.write(  p_txt   => 'Aantal behaalde fouten'
                          , p_x     => 360
                          , p_y     => 180
                          ); 
            --
            -- Label Beoordeling
            --              
            as_pdf3.write(  p_txt   => 'Beoordeling'
                          , p_x     => 470
                          , p_y     => 180
                          );                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
            -- --                                                                                                                                                         
            --
            -- Bepaal me lettertype config
            --
            as_pdf3.set_font(p_family => 'times', p_style => 'N', p_fontsize_pt => 13);             
            --
            -- Tijdelijk foto voor bar + line
            --                                       
                select chart_image	
                into   l_image_bar_line
                from   chart_images	
                where  image_id = 181
                order by image_id desc
                fetch first 1 row only; 
            --
            -- Tijdelijke foto voor donut
            --
                select chart_image	
                into   l_image_donut
                from   chart_images	
                where  image_id = 182
                order by image_id desc
                fetch first 1 row only;
            --
            -- Tijdelijke om me foto te tonen bar + line
            --        
            as_pdf3.put_image(p_img     => l_image_bar_line
                            , p_x       => 20
                            , p_y       => 1100
                            , p_width   =>  600
                            , p_height  =>  500
                            , p_align   =>  'start'
                            , p_valign  =>  'center'
                            );
            -- Tijdelijke om me foto te tonen donut
            --        
            as_pdf3.put_image(p_img     => l_image_donut
                            , p_x       => 350
                            , p_y       => 950
                            , p_width   => 600
                            , p_height  => 500
                            , p_align   => 'start'
                            , p_valign  => 'center'
                            );                                                           
            --
            -- Zet me header voor pagina 3
            --
            p_build_header( p_format                    => 'A4'
                         ,  p_kwaliteits_meeting_values => p_kwaliteits_meeting_values
                         );
            --
            -- Zet me footer voor pagina 3
            --
            p_build_footer( p_format                    => 'A4'
                         ,  p_kwaliteits_meeting_values => p_kwaliteits_meeting_values
                         );
            --
            -- page 4
            -- Voeg een nieuw pagina toe
            --
            as_pdf3.new_page;
            --
            -- Zet me header voor pagina 4
            --
            p_build_header( p_format                    => 'A4'
                         ,  p_kwaliteits_meeting_values => p_kwaliteits_meeting_values
                         );
            --                                
            -- Zet me kleur naar Zwart voor me tabel
            --                                
            as_pdf3.set_color( p_rgb => '000000');                            
            --                                                                                                                                                         
            --
            -- Bepaal me lettertype config
            --
            as_pdf3.set_font(p_family => 'times', p_style => 'B', p_fontsize_pt => 16);
            --
            -- Label Opmerking op ruimteniveau
            --  
            as_pdf3.write(  p_txt   => 'Opmerking op ruimteniveau:'
                          , p_x     => 30
                          , p_y     => 750
                          );
            --
            -- Balk
            --                        
            as_pdf3.vertical_line(    p_x           => 300
                                    , p_y           => 720
                                    , p_height      => 20
                                    , p_line_width  => 550
                                    , p_line_color  => '9ACD32'
                                    ); 
            --
            -- Tussen vertical 1ste
            --                        
            as_pdf3.vertical_line(    p_x           => 110
                                    , p_y           => 720
                                    , p_height      => 20
                                    , p_line_width  => 2
                                    , p_line_color  => '808080'
                                    ); 
            --
            -- Tussen vertical 2de
            --                        
            as_pdf3.vertical_line(    p_x           => 220
                                    , p_y           => 720
                                    , p_height      => 20
                                    , p_line_width  => 2
                                    , p_line_color  => '808080'
                                    );
            --
            -- Tussen vertical 3de
            --                        
            as_pdf3.vertical_line(    p_x           => 320
                                    , p_y           => 720
                                    , p_height      => 20
                                    , p_line_width  => 2
                                    , p_line_color  => '808080'
                                    ); 
            --
            -- Tussen vertical 4de
            --                        
            as_pdf3.vertical_line(    p_x           => 420
                                    , p_y           => 720
                                    , p_height      => 20
                                    , p_line_width  => 2
                                    , p_line_color  => '808080'
                                    );    
            --
            -- Tussen vertical 5de
            --                        
            as_pdf3.vertical_line(    p_x           => 525
                                    , p_y           => 720
                                    , p_height      => 20
                                    , p_line_width  => 2
                                    , p_line_color  => '808080'
                                    );                                                                                                           
            --                                                                                                                           
            -- Bepaal me lettertype config
            --
            as_pdf3.set_font(p_family => 'times', p_style => 'B', p_fontsize_pt => 13);
            --
            -- Label Ruimte nr.     
            as_pdf3.write(  p_txt   => 'Ruimte nr.'
                          , p_x     => 30
                          , p_y     => 725
                          );      
            --
            -- Label Categorie
            --  
            as_pdf3.write(  p_txt   => 'Categorie'
                          , p_x     => 115
                          , p_y     => 725
                          ); 
            --
            -- Label Element
            --  
            as_pdf3.write(  p_txt   => 'Element'
                          , p_x     => 225
                          , p_y     => 725
                          ); 
            --
            -- Label Vuilsoort
            --  
            as_pdf3.write(  p_txt   => 'Vuilsoort'
                          , p_x     => 325
                          , p_y     => 725
                          );  
            --
            -- Label Opmerking
            --  
            as_pdf3.write(  p_txt   => 'Opmerking'
                          , p_x     => 425
                          , p_y     => 725
                          );  
            --
            -- Label Foto nr.
            --  
            as_pdf3.write(  p_txt   => 'Foto nr.'
                          , p_x     => 525
                          , p_y     => 725
                          );                                                                                                                                                                                                                                                       
            --
            -- Zet me footer voor pagina 4
            --
            p_build_footer( p_format                    => 'A4'
                         ,  p_kwaliteits_meeting_values => p_kwaliteits_meeting_values
                         );
            --
            --page 5 
            -- Voeg een nieuw pagina toe
            --
            as_pdf3.new_page;
            --
            -- Zet me header voor pagina 5
            --
            p_build_header( p_format                    => 'A4'
                         ,  p_kwaliteits_meeting_values => p_kwaliteits_meeting_values
                         );
            --
            -- Balk
            --                        
            as_pdf3.vertical_line(    p_x           => 300
                                    , p_y           => 420
                                    , p_height      => 20
                                    , p_line_width  => 550
                                    , p_line_color  => '9ACD32'
                                    ); 
            --
            -- Balk laatste lijn 2de
            --                        
            as_pdf3.vertical_line(    p_x           => 300
                                    , p_y           => 400
                                    , p_height      => 2
                                    , p_line_width  => 550
                                    , p_line_color  => '9ACD32'
                                    );    
            --
            -- Tussen vertical 1ste
            --                        
            as_pdf3.vertical_line(    p_x           => 26
                                    , p_y           => 400
                                    , p_height      => 20
                                    , p_line_width  => 2
                                    , p_line_color  => '9ACD32'
                                    );
            --
            -- Tussen vertical 2de
            --                        
            as_pdf3.vertical_line(    p_x           => 175
                                    , p_y           => 400
                                    , p_height      => 20
                                    , p_line_width  => 2
                                    , p_line_color  => '808080'
                                    );
            --
            -- Tussen vertical 3de lijn ( laatste)
            --                        
            as_pdf3.vertical_line(    p_x           => 574
                                    , p_y           => 400
                                    , p_height      => 20
                                    , p_line_width  => 2
                                    , p_line_color  => '9ACD32'
                                    );   
            --
            -- Balk 2de
            --                        
            as_pdf3.vertical_line(    p_x           => 300
                                    , p_y           => 300
                                    , p_height      => 20
                                    , p_line_width  => 550
                                    , p_line_color  => '9ACD32'
                                    );  
            --
            -- Tussen horizontaal 1ste
            --                        
            as_pdf3.vertical_line(    p_x           => 26
                                    , p_y           => 240
                                    , p_height      => 60
                                    , p_line_width  => 2
                                    , p_line_color  => '9ACD32'
                                    ); 
            --
            -- Balk laatste lijn 2de
            --                        
            as_pdf3.vertical_line(    p_x           => 300
                                    , p_y           => 240
                                    , p_height      => 2
                                    , p_line_width  => 550
                                    , p_line_color  => '9ACD32'
                                    );
            --
            -- Tussen verticaal 1ste
            --                        
            as_pdf3.vertical_line(    p_x           => 300
                                    , p_y           => 280
                                    , p_height      => 2
                                    , p_line_width  => 550
                                    , p_line_color  => '808080'
                                    );                                      
            --
            -- Tussen vertical 1ste
            --                        
            as_pdf3.vertical_line(    p_x           => 300
                                    , p_y           => 260
                                    , p_height      => 2
                                    , p_line_width  => 550
                                    , p_line_color  => '808080'
                                    );
            --
            -- Tussen verticaal 1ste
            --                        
            as_pdf3.vertical_line(    p_x           => 200
                                    , p_y           => 240
                                    , p_height      => 60
                                    , p_line_width  => 2
                                    , p_line_color  => '808080'
                                    );   
            --
            -- Tussen verticaal 2de
            --                        
            as_pdf3.vertical_line(    p_x           => 400
                                    , p_y           => 240
                                    , p_height      => 60
                                    , p_line_width  => 2
                                    , p_line_color  => '808080'
                                    );                                                                                                                      
            --
            -- Tussen verticaal laatste
            --                        
            as_pdf3.vertical_line(    p_x           => 574
                                    , p_y           => 240
                                    , p_height      => 60
                                    , p_line_width  => 2
                                    , p_line_color  => '9ACD32'
                                    );
            --                                                                                                 
            -- Zet me kleur naar Zwart voor me tabel
            --                                
            as_pdf3.set_color( p_rgb => '000000');                            
            --
            -- Bepaal me lettertype config
            --
            as_pdf3.set_font(p_family => 'times', p_style => 'B', p_fontsize_pt => 16);
            --
            -- Label Foto's gebouw technisch:
            --  
            as_pdf3.write(  p_txt   => 'Foto''s''gebouw technisch:'
                          , p_x     => 40
                          , p_y     => 760
                          );  
            --
            -- Bepaal me lettertype config
            --
            as_pdf3.set_font(p_family => 'times', p_style => 'B', p_fontsize_pt => 12);  
            --
            -- Label algemene opmerkingen:
            --                
            as_pdf3.write(  p_txt   => 'Algemene Opmerkingen'
                          , p_x     => 25
                          , p_y     => 450
                          ); 
            --
            -- Bepaal me lettertype config
            --
            as_pdf3.set_font(p_family => 'times', p_style => 'B', p_fontsize_pt => 14);                             
            --
            -- Label Ruimtenummer
            --                
            as_pdf3.write(  p_txt   => 'Ruimtenummer'
                          , p_x     => 30
                          , p_y     => 425
                          ); 
            --
            -- Label Opmerkingen
            --                
            as_pdf3.write(  p_txt   => 'Opmerkingen'
                          , p_x     => 175
                          , p_y     => 425
                          );
            --
            -- Label Algemeen
            --                
            as_pdf3.write(  p_txt   => 'Algemeen'
                          , p_x     => 80
                          , p_y     => 305
                          ); 
            --
            -- Label Status
            --                
            as_pdf3.write(  p_txt   => 'Status'
                          , p_x     => 275
                          , p_y     => 305
                          );
            --
            -- Label Opmerkingen
            --                
            as_pdf3.write(  p_txt   => 'Opmerkingen'
                          , p_x     => 450
                          , p_y     => 305
                          );                                                                                          
            --
            -- Bepaal me lettertype config
            --
            as_pdf3.set_font(p_family => 'times', p_style => 'B', p_fontsize_pt => 12);                            
            --
            -- Label Overige-en hygiëne aspecten
            --                
            as_pdf3.write(  p_txt   => 'Overige-en hygiëne aspecten'
                          , p_x     => 30
                          , p_y     => 325
                          );                                                                                                                                     
            --
            -- Zet me footer voor pagina 5
            --
            p_build_footer( p_format                    => 'A4'
                         ,  p_kwaliteits_meeting_values => p_kwaliteits_meeting_values
                         ); 
            --
            --                         
        end p_build_kwaliteits_meting_body;
        --
    begin
        -- main
        as_pdf3.init;
        as_pdf3.set_page_format('A4');
        as_pdf3.set_page_orientation('PORTRAIT');
        as_pdf3.set_page_proc(  q'~
                                    begin
                                    as_pdf3.set_font( p_family      => 'times'
                                                    , p_style       => 'N'
                                                    , p_fontsize_pt => 12
                                                    );
                                    as_pdf3.put_txt(p_txt => '~'
                                                    || 'Blad'
                                                    || ' #PAGE_NR# '
                                                    || 'Van'
                                                    || q'~ "PAGE_COUNT#'
                                            , p_x   => 475
                                            , p_y   => 45 
                                            );
                                    end;~'
                               );          
        --
        -- Maak de header aan voor page 1
        p_build_foto_header(p_format => 'A4');
        -- Maak de body aan
        p_build_kwaliteits_meting_body(    p_kwaliteits_meeting_values => p_kwaliteits_meeting_values
                                       );
        -- Maak de footer aan voor laatste page
            p_build_footer( p_format                    => 'A4'
                         ,  p_kwaliteits_meeting_values => p_kwaliteits_meeting_values
                         );
        -- set global pdf var
        gb_pdf := as_pdf3.get_pdf;
        -- end logging
        --
    exception
    when others 
    then
        raise;
    end p_build_kwaliteits_meting_pdf;
    --       
    -----------------------------------------------------------------------------
    --
    --  ** $2, build and return kwaliteits meting pdf **
    function f_get_kwaliteits_meting_pdf(   p_kwaliteits_meeting_values  t_kwaliteits_meeting_values  )
    return blob
    is
    begin

        -- build pdf
        p_build_kwaliteits_meting_pdf   ( p_kwaliteits_meeting_values => p_kwaliteits_meeting_values
                                        );

        return gb_pdf;
    exception
    when others then
        raise;
    end f_get_kwaliteits_meting_pdf;
    --
    --
    -------------------------------------------------------------------------------
    --
    --    
end icca_kwaliteits_meting_pdf_template;
/