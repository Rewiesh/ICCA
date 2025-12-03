create or replace package body icca_pdf_generator as    
    --
    -- ========================================================================
    -- Package Body: icca_pdf_generator
    -- Versie: 1.0.0 - Fase 1
    -- ========================================================================
    --

    -- constanten
   c_pdf_service_url   constant varchar2(200) := 'http://localhost:3000';
   c_endpoint_template constant varchar2(200) := '/generate-pdf-template';
   c_endpoint_refresh  constant varchar2(200) := '/templates/refresh';

    --
    -- ========================================================================
    -- Private functions
    -- ========================================================================
    --

    --
    -- Valideer template naam tegen whitelist
    --
   function f_is_valid_template (
      p_template_name in varchar2
   ) return boolean is
   begin
      return p_template_name in ( 'BURO_HENNIE_DEKKER',
                                  'ICCA',
                                  'ICCA_ZONDER_CIJFERS',
                                  'FASE_CONTROL' );
   end f_is_valid_template;

    --
    -- ========================================================================
    -- Public functions
    -- ========================================================================
    --

    --
    -- Roep Node.js PDF service aan
    --
   function f_call_pdf_service (
      p_template_name in varchar2,
      p_json_data     in clob
   ) return blob is
      l_pdf_blob      blob;
      l_url           varchar2(500);
      l_response_code number;
   begin
      apex_debug.message(
         'f_call_pdf_service: template=%s',
         p_template_name
      );
        
        -- valideer template naam
      if not f_is_valid_template(p_template_name) then
         apex_debug.error(
            'Ongeldige template naam: %s',
            p_template_name
         );
         raise_application_error(
            -20003,
            'Ongeldige template naam: ' || p_template_name
         );
      end if;
        
        -- bouw url
      l_url := c_pdf_service_url || c_endpoint_template;
      apex_debug.info(
         'Calling PDF service: url=%s, json_size=%s',
         l_url,
         dbms_lob.getlength(p_json_data)
      );
      dbms_output.put_line('Calling PDF service: url='
                           || l_url
                           || ', json_size=' || dbms_lob.getlength(p_json_data));
        
        -- reset apex web service headers
      apex_web_service.g_request_headers.delete;
        
        -- set headers
      apex_web_service.g_request_headers(1).name := 'Content-Type';
      apex_web_service.g_request_headers(1).value := 'application/json; charset=UTF-8';
        
        -- make request
      l_pdf_blob := apex_web_service.make_rest_request_b(
         p_url         => l_url,
         p_http_method => 'POST',
         p_body        => p_json_data
      );

      l_response_code := apex_web_service.g_status_code;
      apex_debug.info(
         'PDF service response: status=%s, size=%s bytes',
         l_response_code,
         nvl(
            dbms_lob.getlength(l_pdf_blob),
            0
         )
      );
        
        -- check response
      if l_response_code != 200 then
         apex_debug.error(
            'PDF service error: HTTP %s',
            l_response_code
         );
         raise_application_error(
            -20004,
            'PDF service error: HTTP ' || l_response_code
         );
      end if;

      if l_pdf_blob is null
      or dbms_lob.getlength(l_pdf_blob) < 100 then
         apex_debug.error('PDF generation failed: response te klein');
         raise_application_error(
            -20005,
            'PDF generation failed: response te klein ('
            || nvl(
               to_char(dbms_lob.getlength(l_pdf_blob)),
               'NULL'
            )
            || ' bytes)'
         );
      end if;

      return l_pdf_blob;
   exception
      when others then
         apex_debug.error(
            'Error in f_call_pdf_service: %s',
            sqlerrm
         );
         raise;
   end f_call_pdf_service;

    --
    -- Refresh template cache in Node.js service
    --
   procedure p_refresh_template_cache is
      l_url           varchar2(500);
      l_response      clob;
      l_response_code number;
   begin
      apex_debug.message('p_refresh_template_cache: start');
            
            -- bouw url
      l_url := c_pdf_service_url || c_endpoint_refresh;
      apex_debug.info(
         'Calling refresh endpoint: %s',
         l_url
      );
            
            -- reset headers
      apex_web_service.g_request_headers.delete;
            
            -- make request
      l_response := apex_web_service.make_rest_request(
         p_url         => l_url,
         p_http_method => 'GET'
      );
      l_response_code := apex_web_service.g_status_code;
      apex_debug.info(
         'Refresh response: status=%s, response=%s',
         l_response_code,
         substr(
            l_response,
            1,
            200
         )
      );
      if l_response_code != 200 then
         apex_debug.error(
            'Template refresh failed: HTTP %s',
            l_response_code
         );
         raise_application_error(
            -20006,
            'Template refresh failed: HTTP ' || l_response_code
         );
      end if;

      apex_debug.message('Template cache refreshed successfully');
   exception
      when others then
         apex_debug.error(
            'Error in p_refresh_template_cache: %s',
            sqlerrm
         );
         raise;
   end p_refresh_template_cache;

    --
    -- Hoofdfunctie: genereer PDF voor audit
    --
   function f_generate_audit_pdf (
      p_adt_id in number
   ) return blob is
      l_template_name varchar2(100);
      l_json_data     clob;
      l_pdf_blob      blob;
   begin
      apex_debug.message(
         'f_generate_audit_pdf: start for adt_id=%s',
         p_adt_id
      );
        
        -- haal template type op via client
      begin
         select case 
                  when cnt.audit_report_type = 'ICCA_ZONDER_CIJFER' then 'ICCA_ZONDER_CIJFERS'
                  when cnt.audit_report_type = 'FASE_CONTROL' then 'FASE_CONTROL'
                  when cnt.audit_report_type = 'BURO_HENNIE_DEKKER' then 'BURO_HENNIE_DEKKER'
                  when cnt.audit_report_type = 'ICCA' then 'ICCA'
                  else 'ICCA'
                  end
           into l_template_name
           from icca_audits adt
           join icca_clients cnt
         on cnt.id = adt.cnt_id
          where adt.id = p_adt_id;

      exception
         when no_data_found then
            apex_debug.error(
               'Audit %s niet gevonden',
               p_adt_id
            );
            raise_application_error(
               -20007,
               'Audit niet gevonden: ' || p_adt_id
            );
      end;

      apex_debug.info(
         'Template type: %s',
         l_template_name
      );
      dbms_output.put_line('Template type: ' || l_template_name);
        
        -- bouw JSON op basis van template type
      l_json_data := case upper(trim(l_template_name))
          when 'BURO_HENNIE_DEKKER'   then icca_pdf_buro_hennie_dekker_data.f_get_main_json(p_adt_id)
          when 'ICCA'                 then icca_pdf_icca_data.f_get_main_json(p_adt_id)
          when 'ICCA_ZONDER_CIJFERS'  then icca_pdf_icca_zonder_cijfers_data.f_get_main_json(p_adt_id)
          when 'FASE_CONTROL'         then icca_pdf_fase_control_data.f_get_main_json(p_adt_id)
          else icca_pdf_icca_data.f_get_main_json(p_adt_id) -- fallback
      end;

      dbms_output.put_line('JSON data: ' || l_json_data);
        
      -- roep PDF service aan
      l_pdf_blob := f_call_pdf_service(
         l_template_name,
         l_json_data
      );
      apex_debug.message(
         'PDF generated successfully: %s bytes',
         dbms_lob.getlength(l_pdf_blob)
      );
      dbms_output.put_line('PDF generated successfully: '
                           || dbms_lob.getlength(l_pdf_blob) || ' bytes');
      return l_pdf_blob;
   exception
      when others then
         apex_debug.error(
            'Error in f_generate_audit_pdf: %s',
            sqlerrm
         );
         raise;
   end f_generate_audit_pdf;

    --
    -- Test functie: genereer PDF van raw HTML
    -- Stuurt raw HTML naar service, krijgt binary PDF terug
    --
   function f_generate_pdf_from_html (
      p_html in clob
   ) return blob is
      l_pdf_blob  blob;
      l_url       varchar2(500);
      l_html_size number;
   begin
      apex_debug.message('f_generate_pdf_from_html: start');
      l_html_size := dbms_lob.getlength(p_html);
      apex_debug.info(
         'HTML size: %s bytes',
         l_html_size
      );
      if p_html is null
      or l_html_size < 10 then
         apex_debug.error('HTML is leeg of te klein');
         raise_application_error(
            -20008,
            'HTML is leeg of te klein'
         );
      end if;
        
        -- bouw url
      l_url := c_pdf_service_url || '/generate-pdf';
      apex_debug.info(
         'Calling PDF service (raw HTML mode): %s',
         l_url
      );
        
        -- reset headers en set Content-Type voor raw HTML
      apex_web_service.g_request_headers.delete;
      apex_web_service.g_request_headers(1).name := 'Content-Type';
      apex_web_service.g_request_headers(1).value := 'text/html; charset=UTF-8';
        
        -- call service met raw HTML body, krijg binary PDF terug
      l_pdf_blob := apex_web_service.make_rest_request_b(
         p_url         => l_url,
         p_http_method => 'POST',
         p_body        => p_html
      );

      apex_debug.info(
         'PDF received: %s bytes',
         nvl(
            dbms_lob.getlength(l_pdf_blob),
            0
         )
      );
        
        -- valideer response
      if l_pdf_blob is null
      or dbms_lob.getlength(l_pdf_blob) < 100 then
         apex_debug.error('PDF generation failed: response te klein');
         raise_application_error(
            -20009,
            'PDF generation failed: response te klein ('
            || nvl(
               to_char(dbms_lob.getlength(l_pdf_blob)),
               'NULL'
            )
            || ' bytes)'
         );
      end if;

      apex_debug.message(
         'PDF generated successfully: %s bytes',
         dbms_lob.getlength(l_pdf_blob)
      );
      return l_pdf_blob;
   exception
      when others then
         apex_debug.error(
            'Error in f_generate_pdf_from_html: %s',
            sqlerrm
         );
         raise;
   end f_generate_pdf_from_html;

    --
    -- Test: genereer PDF met volledige dummy data (Hennie Dekker)
    -- Standalone test met hardcoded JSON uit test-buro-hennie.html
    --
   function f_test_hennie_dekker_dummy return blob is
      l_pdf_blob      blob;
      l_json_data     clob;
      l_url           varchar2(500);
      l_response_code number;
   begin
      apex_debug.message('f_test_hennie_dekker_dummy: start');
      dbms_output.put_line('========================================');
      dbms_output.put_line('Template PDF Test - Hennie Dekker Dummy');
      dbms_output.put_line('========================================');
      dbms_output.put_line('');

    -- Init JSON data (hardcoded from test-buro-hennie.html)
      l_json_data := to_clob(q'[
    {
    "template_name": "BURO_HENNIE_DEKKER",
    "data": {
        "audit_info": {
            "rapport_titel": "Rapportage VC/Audit wk 16-2025 Grote Klant",
            "opdrachtgever": "Grote Klant BV",
            "adres": "Industrieweg 100",
            "postcode_plaats": "1000 AA Amsterdam",
            "plaats": "Amsterdam",
            "tav": "Mevr. J. Jansen",
            "controle_uitgevoerd_op": "12-4-2025",
            "controle_periode": "wk 16-2025",
            "tijdstip_controle": "14:30",
            "controlenummer": "16371",
            "uitgevoerd_door": "Piet Puk",
            "controle_uitgevoerd_door": "Hennie Dekker",
            "client_logo_url": "http://localhost:3000/uploads/4f5a03a1a4c141e68068d95d63136275.jpg",
            "handtekening_url": "http://localhost:3000/uploads/1e014af35e0046cea602e6475bc41799.png"
        },
        "categories": [
            {
                "categorie_naam": "Bureaukamer",
                "tel_element": 5,
                "goedkeurgrens": 4,
                "aantal_behaalde_fouten": 1,
                "beoordeling": "Onvoldoende"
            },
            {
                "categorie_naam": "Sanitaire ruimte",
                "tel_element": 4,
                "goedkeurgrens": 3,
                "aantal_behaalde_fouten": 0,
                "beoordeling": "Voldoende"
            },
            {
                "categorie_naam": "Verkeersruimte",
                "tel_element": 3,
                "goedkeurgrens": 2,
                "aantal_behaalde_fouten": 0,
                "beoordeling": "Voldoende"
            },
            {
                "categorie_naam": "Vergaderzaal",
                "tel_element": 2,
                "goedkeurgrens": 2,
                "aantal_behaalde_fouten": 0,
                "beoordeling": "Onvoldoende"
            },
            {
                "categorie_naam": "Keuken",
                "tel_element": 3,
                "goedkeurgrens": 3,
                "aantal_behaalde_fouten": 1,
                "beoordeling": "Voldoende"
            },
            {
                "categorie_naam": "Entree",
                "tel_element": 1,
                "goedkeurgrens": 1,
                "aantal_behaalde_fouten": 0,
                "beoordeling": "Voldoende"
            }
        ],
        "gemiddeld_cijfer_data": [
            { "periode": "10/28-20-41", "cijfer": 7.0 },
            { "periode": "10/24-21-8", "cijfer": 9.0 },
            { "periode": "11/28-21-45", "cijfer": 8.0 },
            { "periode": "12/14-22-39", "cijfer": 9.0 },
            { "periode": "1/3/41-23-15", "cijfer": 8.5 },
            { "periode": "13/35-23-11", "cijfer": 9.0 },
            { "periode": "15/16-24-37", "cijfer": 8.0 },
            { "periode": "16/10-25-15", "cijfer": 9.0 }
        ],
        "meest_voorkomende_fouten": [
            {
                "categorie_naam": "Bureaukamer",
                "fouten": [
                    { "element": "deur deurpost", "aantal": 1, "methode": "" },
                    { "element": "plafond", "aantal": 2, "methode": "Gehecht vuil" },
                    { "element": "vloer", "aantal": 1, "methode": "Niet aangevuld" }
                ]
            },
            {
                "categorie_naam": "Sanitaire ruimte",
                "fouten": [
                    { "element": "closet", "aantal": 3, "methode": "Niet gehecht vuil" },
                    { "element": "spiegel", "aantal": 1, "methode": "Gehecht vuil" },
                    { "element": "wastafel", "aantal": 2, "methode": "Niet aangevuld" }
                ]
            },
            {
                "categorie_naam": "Keuken",
                "fouten": [
                    { "element": "aanrecht", "aantal": 2, "methode": "Gehecht vuil" },
                    { "element": "koelkast", "aantal": 1, "methode": "Niet gehecht vuil" },
                    { "element": "magnetron", "aantal": 1, "methode": "Gehecht vuil" }
                ]
            }
        ],
        "vuilsoorten_resultaten": [
            { "label": "aanslag", "score": 15.5 },
            { "label": "dicht stof", "score": 90.0 },
            { "label": "gehecht vuil methode", "score": 0 },
            { "label": "gehecht vuil vlek vingertast", "score": 100.0 },
            { "label": "niet aangevuld", "score": 0 },
            { "label": "niet gehecht vuil licht stof", "score": 0 },
            { "label": "niet gehecht vuil methode", "score": 85.5 },
            { "label": "niet geleegd", "score": 25.5 },
            { "label": "spinrag", "score": 0 }
        ],
        "foutsoorten_resultaten": [
            { "label": "Fout", "score": 100.0 },
            { "label": "Methode-fout", "score": 34.5 },
            { "label": "Niet gehecht vuil", "score": 25.5 },
            { "label": "Gehecht vuil", "score": 65.5 },
            { "label": "Niet aangevuld/geleegd", "score": 25.5 }
        ],
        "gecontroleerde_ruimtes": [
            "Bg-Keu.R2.3",
            "Bg-Bes.R2.2",
            "Bg-Ent.R2.1",
            "Bg-Dou.2.4",
            "Bg-Toi.R2.5"
        ],
        "opmerkingen": [
            {
                "ruimte": "Bg-Keu.R2.3",
                "tekst": "De kraan lekt (keuken/pantry). Dit is al meerdere malen aangegeven. Advies: de kraan zsm laten vervangen."
            },
            {
                "ruimte": "Bg-Dou.2.4",
                "tekst": "De doucheruimte wordt als opslag/werkast gebruikt"
            },
            {
                "ruimte": "Bg-Toi.R2.5",
                "tekst": "De meeste elementen zijn gedateerd maar schoon."
            },
            {
                "ruimte": "Bg-Ent R2.1",
                "tekst": "De huidige kokosmat is aan vervanging toe."
            }
            ,
            {
                "ruimte": "Bg-Ent R2.1",
                "tekst": "De huidige kokosmat is aan vervanging toe."
            }
            ,
            {
                "ruimte": "Bg-Ent R2.1",
                "tekst": "De huidige kokosmat is aan vervanging toe."
            }
        ],
        "element_fouten_top": [
            { "label": "deur deurpost", "score": 100 },
            { "label": "vloer", "score": 80 },
            { "label": "bureau", "score": 60 },
            { "label": "prullenbak", "score": 40 },
            { "label": "vensterbank", "score": 20 }
        ],
        "pareto_data": [
            { "label": "Vloer", "aantal": 10, "percentage": 50 },
            { "label": "Deur", "aantal": 6, "percentage": 80 },
            { "label": "Bureau", "aantal": 2, "percentage": 90 },
            { "label": "Prullenbak", "aantal": 1, "percentage": 95 },
            { "label": "Vensterbank", "aantal": 1, "percentage": 100 }
        ],
        "pareto_info": {
            "aantal_elementen": 2,
            "element_namen": "vloer en deur",
            "totaal_percentage": "80"
        },
        "opmerkingen_logboek": [
            { "tekst": "-1-Kel.Werkplaats vloer gehecht vuil vlek vingertast" },
            { "tekst": "Bg-Hal.A5.1 deur deurpost spinrag, Garagedeur" },
            { "tekst": "-1-Kel.Pompkelder lichtknop contactdoos spinrag" },
            { "tekst": "Bg-Hal.A5.1 vloer spinrag" },
            { "tekst": "-1-Kel.Pompkelder vloer gehecht vuil vlek vingertast, Zijkanten met name" },
            { "tekst": "Bg-Ent.A5.4 deur deurpost gehecht vuil vlek vingertast, Tevens spinrag" },
            { "tekst": "Bg-Bur.A5.3 vloer gehecht vuil vlek vingertast, Tevens verstoringen" },
            { "tekst": "Bg-Ent.A5.4 vloer gehecht vuil vlek vingertast, Hoek" },
            { "tekst": "Bg-Bur.A5.3 kast laag gehecht vuil vlek vingertast, Aanrechtblad en wasbak tevens verstoringen" },
            { "tekst": "Bg-Ent.A5.4 rand richel tot reikhoogte spinrag, Buitenzijde leuning" },
            { "tekst": "Bg-Bur.A5.3 kast hoog dicht stof, Bovenzijde keukenkastje" }
        ],
        "logboek_fotos": [
            { "url": "http://localhost:3000/uploads/86fb7bb1c4b741f59b788c50fef435de.png", "beschrijving": "Verstoring", "page_break": false },
            { "url": "http://localhost:3000/uploads/86fb7bb1c4b741f59b788c50fef435de.png", "beschrijving": "Gehecht vuil", "page_break": false },
            { "url": "http://localhost:3000/uploads/86fb7bb1c4b741f59b788c50fef435de.png", "beschrijving": "Niet aangevuld", "page_break": false },
            { "url": "http://localhost:3000/uploads/86fb7bb1c4b741f59b788c50fef435de.png", "beschrijving": "Spinrag", "page_break": false },
            { "url": "http://localhost:3000/uploads/86fb7bb1c4b741f59b788c50fef435de.png", "beschrijving": "Dicht stof", "page_break": false },
            { "url": "http://localhost:3000/uploads/86fb7bb1c4b741f59b788c50fef435de.png", "beschrijving": "Vlek vingertast", "page_break": false },
            { "url": "http://localhost:3000/uploads/86fb7bb1c4b741f59b788c50fef435de.png", "beschrijving": "Niet geleegd", "page_break": true },
            { "url": "http://localhost:3000/uploads/86fb7bb1c4b741f59b788c50fef435de.png", "beschrijving": "Aanslag", "page_break": false },
            { "url": "http://localhost:3000/uploads/86fb7bb1c4b741f59b788c50fef435de.png", "beschrijving": "Methode fout", "page_break": false },
            { "url": "http://localhost:3000/uploads/86fb7bb1c4b741f59b788c50fef435de.png", "beschrijving": "Algemeen", "page_break": false }
        ],
        "opmerkingen_gebouwtechnisch": [
            { "tekst": "Bgg-Ent.A5.4: Buitendeur garage vol met spinrag en gedroogd gras." },
            { "tekst": "Bg-Hal.A5.1: De vloerbedekking in de hal vertoont slijtage." },
            { "tekst": "Bg-Keu.R2.3: De kraan in de pantry lekt en moet vervangen worden." },
            { "tekst": "Bgg-Ent.A5.4: Buitendeur garage vol met spinrag en gedroogd gras." },
            { "tekst": "Bg-Hal.A5.1: De vloerbedekking in de hal vertoont slijtage." },
            { "tekst": "Bg-Keu.R2.3: De kraan in de pantry lekt en moet vervangen worden." },
            { "tekst": "Bg-Ent.A5.4: Buitendeur garage vol met spinrag en gedroogd gras." },
            { "tekst": "Bg-Hal.A5.1: De vloerbedekking in de hal vertoont slijtage." },
            { "tekst": "Bg-Keu.R2.3: De kraan in de pantry lekt en moet vervangen worden." },
            { "tekst": "Bg-Ent.A5.4: Buitendeur garage vol met spinrag en gedroogd gras." },
            { "tekst": "Bg-Hal.A5.1: De vloerbedekking in de hal vertoont slijtage." }
        ],
        "fotos_gebouwtechnisch": [
            { "url": "http://localhost:3000/uploads/86fb7bb1c4b741f59b788c50fef435de.png", "beschrijving": "Lekkende kraan", "page_break": false },
            { "url": "http://localhost:3000/uploads/86fb7bb1c4b741f59b788c50fef435de.png", "beschrijving": "Versleten vloer", "page_break": false },
            { "url": "http://localhost:3000/uploads/86fb7bb1c4b741f59b788c50fef435de.png", "beschrijving": "Spinrag buitendeur", "page_break": false },
            { "url": "http://localhost:3000/uploads/86fb7bb1c4b741f59b788c50fef435de.png", "beschrijving": "Beschadigde deur", "page_break": false },
            { "url": "http://localhost:3000/uploads/86fb7bb1c4b741f59b788c50fef435de.png", "beschrijving": "Spinrag buitendeur", "page_break": false },
            { "url": "http://localhost:3000/uploads/86fb7bb1c4b741f59b788c50fef435de.png", "beschrijving": "Spinrag buitendeur", "page_break": false },
            { "url": "http://localhost:3000/uploads/86fb7bb1c4b741f59b788c50fef435de.png", "beschrijving": "Spinrag buitendeur", "page_break": false },
            { "url": "http://localhost:3000/uploads/86fb7bb1c4b741f59b788c50fef435de.png", "beschrijving": "Spinrag buitendeur", "page_break": false },
            { "url": "http://localhost:3000/uploads/86fb7bb1c4b741f59b788c50fef435de.png", "beschrijving": "Spinrag buitendeur", "page_break": false },
            { "url": "http://localhost:3000/uploads/86fb7bb1c4b741f59b788c50fef435de.png", "beschrijving": "Spinrag buitendeur", "page_break": false }
        ],
        "kpi_onderwerpen": [
            { "algemeen": "01. Aanwezigheid klassenkaart in de klas", "status": "N.v.t.", "opmerkingen": "" },
            { "algemeen": "04. Uitstraling van de werkkast/--wagen", "status": "N.v.t.", "opmerkingen": "" },
            { "algemeen": "03. Buiten entree zand vrij", "status": "N.v.t.", "opmerkingen": "" },
            { "algemeen": "02. Aanwezigheid logboek en gebruik ervan.", "status": "N.v.t.", "opmerkingen": "" },
            { "algemeen": "01. Aanwezigheid klassenkaart in de klas", "status": "N.v.t.", "opmerkingen": "" },
            { "algemeen": "04. Uitstraling van de werkkast/--wagen", "status": "N.v.t.", "opmerkingen": "" },
            { "algemeen": "03. Buiten entree zand vrij", "status": "N.v.t.", "opmerkingen": "" },
            { "algemeen": "02. Aanwezigheid logboek en gebruik ervan.", "status": "N.v.t.", "opmerkingen": "" },
            { "algemeen": "01. Aanwezigheid klassenkaart in de klas", "status": "N.v.t.", "opmerkingen": "" },
            { "algemeen": "04. Uitstraling van de werkkast/--wagen", "status": "N.v.t.", "opmerkingen": "" },
            { "algemeen": "03. Buiten entree zand vrij", "status": "N.v.t.", "opmerkingen": "" },
            { "algemeen": "02. Aanwezigheid logboek en gebruik ervan.", "status": "N.v.t.", "opmerkingen": "" }
        ]
    }
    }
    ]');
      dbms_output.put_line('  ✓ Data JSON: '
                           || dbms_lob.getlength(l_json_data) || ' bytes');

        -- Call PDF service directly
      l_url := c_pdf_service_url || c_endpoint_template;
      dbms_output.put_line('  URL: ' || l_url);
        
        -- reset headers
      apex_web_service.g_request_headers.delete;
      apex_web_service.g_request_headers(1).name := 'Content-Type';
      apex_web_service.g_request_headers(1).value := 'application/json; charset=UTF-8';
        
        -- make request
      l_pdf_blob := apex_web_service.make_rest_request_b(
         p_url         => l_url,
         p_http_method => 'POST',
         p_body        => l_json_data
      );

      l_response_code := apex_web_service.g_status_code;
      dbms_output.put_line('  ✓ Response code: ' || l_response_code);
      if l_response_code != 200 then
         dbms_output.put_line('  ✗ ERROR: HTTP ' || l_response_code);
         raise_application_error(
            -20013,
            'PDF service error: HTTP ' || l_response_code
         );
      end if;

      if l_pdf_blob is null
      or dbms_lob.getlength(l_pdf_blob) < 100 then
         dbms_output.put_line('  ✗ ERROR: PDF te klein of leeg');
         raise_application_error(
            -20014,
            'PDF generation failed: response te klein'
         );
      end if;

      dbms_output.put_line('  ✓ PDF ontvangen: '
                           || dbms_lob.getlength(l_pdf_blob) || ' bytes');
      return l_pdf_blob;
   exception
      when others then
         apex_debug.error(
            'Error in f_test_hennie_dekker_dummy: %s',
            sqlerrm
         );
         dbms_output.put_line('Error: ' || sqlerrm);
         raise;
   end f_test_hennie_dekker_dummy;

    --
    -- Test functie: genereer PDF met template en dummy data (alleen pagina 1)
    -- Standalone - roept direct Node.js service aan zonder andere package functies
    --
   function f_test_template_page1 return blob is
      l_pdf_blob      blob;
      l_json_data     clob;
      l_request_body  clob;
      l_url           varchar2(500);
      l_response_code number;
   begin
      apex_debug.message('f_test_template_page1: start');
      dbms_output.put_line('========================================');
      dbms_output.put_line('Template PDF Test - Pagina 1');
      dbms_output.put_line('========================================');
      dbms_output.put_line('');
        
        -- stap 1: bouw dummy data JSON
      dbms_output.put_line('Step 1: Bouw dummy data...');
      apex_json.initialize_clob_output;
      apex_json.open_object;
        
        -- audit_info section
      apex_json.open_object('audit_info');
      apex_json.write(
         'rapport_titel',
         'Rapportage VC/Audit wk 15-2025 HHNK'
      );
      apex_json.write(
         'opdrachtgever',
         'HHNK'
      );
      apex_json.write(
         'adres',
         'Flevoweg 2'
      );
      apex_json.write(
         'postcode_plaats',
         '1441 CZ Purmerend'
      );
      apex_json.write(
         'plaats',
         'Middeneer'
      );
      apex_json.write(
         'tav',
         'Dhr. T. Hegeman'
      );
      apex_json.write(
         'controle_uitgevoerd_op',
         '10-4-2025'
      );
      apex_json.write(
         'controle_periode',
         'wk 15-2025'
      );
      apex_json.write(
         'tijdstip_controle',
         '21:02'
      );
      apex_json.write(
         'controlenummer',
         '16370'
      );
      apex_json.write(
         'uitgevoerd_door',
         'Unen, Marina Twisk'
      );
      apex_json.write(
         'controle_uitgevoerd_door',
         'Hennie Dekker Dekker'
      );
      apex_json.close_object; -- audit_info
        
        -- categories array
      apex_json.open_array('categories');
        
        -- categorie 1: Bureaukamer
      apex_json.open_object;
      apex_json.write(
         'categorie_naam',
         'Bureaukamer'
      );
      apex_json.write(
         'tel_element',
         2
      );
      apex_json.write(
         'goedkeurgrens',
         2
      );
      apex_json.write(
         'aantal_behaalde_fouten',
         0
      );
      apex_json.write(
         'beoordeling',
         'Voldoende'
      );
      apex_json.close_object;
        
        -- categorie 2: Sanitaire ruimte
      apex_json.open_object;
      apex_json.write(
         'categorie_naam',
         'Sanitaire ruimte'
      );
      apex_json.write(
         'tel_element',
         3
      );
      apex_json.write(
         'goedkeurgrens',
         3
      );
      apex_json.write(
         'aantal_behaalde_fouten',
         0
      );
      apex_json.write(
         'beoordeling',
         'Voldoende'
      );
      apex_json.close_object;
        
        -- categorie 3: Verkeersruimte
      apex_json.open_object;
      apex_json.write(
         'categorie_naam',
         'Verkeersruimte'
      );
      apex_json.write(
         'tel_element',
         2
      );
      apex_json.write(
         'goedkeurgrens',
         2
      );
      apex_json.write(
         'aantal_behaalde_fouten',
         0
      );
      apex_json.write(
         'beoordeling',
         'Voldoende'
      );
      apex_json.close_object;
      apex_json.close_array; -- categories

      apex_json.close_object; -- root

      l_json_data := apex_json.get_clob_output;
      apex_json.free_output;
      dbms_output.put_line('  ✓ Data JSON: '
                           || dbms_lob.getlength(l_json_data) || ' bytes');
        
        -- stap 2: bouw request body met template_name en data
      dbms_output.put_line('');
      dbms_output.put_line('Step 2: Bouw request body...');
      apex_json.initialize_clob_output;
      apex_json.open_object;
      apex_json.write(
         'template_name',
         'BURO_HENNIE_DEKKER'
      );
      apex_json.write(
         'data',
         l_json_data
      );
      apex_json.close_object;
      l_request_body := apex_json.get_clob_output;
      apex_json.free_output;
      dbms_output.put_line('  ✓ Request body: '
                           || dbms_lob.getlength(l_request_body) || ' bytes');
        
        -- stap 3: roep Node.js service aan
      dbms_output.put_line('');
      dbms_output.put_line('Step 3: Roep PDF service aan...');
      l_url := c_pdf_service_url || '/generate-pdf-template';
      dbms_output.put_line('  URL: ' || l_url);
      dbms_output.put_line('  Template: BURO_HENNIE_DEKKER');
        
        -- reset headers en set Content-Type
      apex_web_service.g_request_headers.delete;
      apex_web_service.g_request_headers(1).name := 'Content-Type';
      apex_web_service.g_request_headers(1).value := 'application/json';
        
        -- call service (binary response verwacht)
      l_pdf_blob := apex_web_service.make_rest_request_b(
         p_url         => l_url,
         p_http_method => 'POST',
         p_body        => l_request_body
      );

      l_response_code := apex_web_service.g_status_code;
      dbms_output.put_line('  ✓ Response code: ' || l_response_code);
        
        -- valideer response
      if l_response_code != 200 then
         dbms_output.put_line('  ✗ ERROR: HTTP ' || l_response_code);
         raise_application_error(
            -20011,
            'PDF service error: HTTP ' || l_response_code
         );
      end if;

      if l_pdf_blob is null
      or dbms_lob.getlength(l_pdf_blob) < 100 then
         dbms_output.put_line('  ✗ ERROR: PDF te klein of leeg');
         raise_application_error(
            -20012,
            'PDF generation failed: response te klein ('
            || nvl(
               to_char(dbms_lob.getlength(l_pdf_blob)),
               'NULL'
            )
            || ' bytes)'
         );
      end if;

      dbms_output.put_line('  ✓ PDF ontvangen: '
                           || dbms_lob.getlength(l_pdf_blob) || ' bytes');
        
        -- valideer PDF header
      declare
         l_header      raw(10);
         l_header_text varchar2(10);
      begin
         l_header := dbms_lob.substr(
            l_pdf_blob,
            10,
            1
         );
         l_header_text := utl_raw.cast_to_varchar2(dbms_lob.substr(
            l_pdf_blob,
            8,
            1
         ));

         dbms_output.put_line('');
         dbms_output.put_line('PDF Validatie:');
         dbms_output.put_line('  Header: ' || l_header_text);
         if substr(
            l_header_text,
            1,
            4
         ) = '%PDF' then
            dbms_output.put_line('  Status: ✓ VALIDE PDF!');
         else
            dbms_output.put_line('  Status: ✗ GEEN VALIDE PDF!');
            raise_application_error(
               -20010,
               'Geen valide PDF gegenereerd'
            );
         end if;
      end;

      dbms_output.put_line('');
      dbms_output.put_line('========================================');
      dbms_output.put_line('Test SUCCESVOL!');
      dbms_output.put_line('========================================');
      apex_debug.message(
         'Template test successful: %s bytes',
         dbms_lob.getlength(l_pdf_blob)
      );
      return l_pdf_blob;
   exception
      when others then
         dbms_output.put_line('');
         dbms_output.put_line('========================================');
         dbms_output.put_line('ERROR!');
         dbms_output.put_line('========================================');
         dbms_output.put_line('Error: ' || sqlerrm);
         dbms_output.put_line('');
         dbms_output.put_line('Mogelijke oorzaken:');
         dbms_output.put_line('  1. Node.js service draait niet');
         dbms_output.put_line('  2. Template BURO_HENNIE_DEKKER niet gevonden');
         dbms_output.put_line('  3. Template syntax error');
         dbms_output.put_line('  4. JSON data formaat incorrect');
         apex_debug.error(
            'Error in f_test_template_page1: %s',
            sqlerrm
         );
         raise;
   end f_test_template_page1;

    --
    -- Test: genereer PDF met volledige dummy data (ICCA Rapport)
    -- Standalone test met hardcoded JSON uit test-templates.html
    --
   function f_test_icca_rapport_dummy return blob is
      l_pdf_blob      blob;
      l_json_data     clob;
      l_url           varchar2(500);
      l_response_code number;
   begin
      apex_debug.message('f_test_icca_rapport_dummy: start');
      dbms_output.put_line('========================================');
      dbms_output.put_line('Template PDF Test - ICCA Rapport Dummy');
      dbms_output.put_line('========================================');
      dbms_output.put_line('');

    -- Init JSON data (hardcoded from test-templates.html)
      l_json_data := to_clob(q'[
    {
    "template_name": "ICCA_RAPPORT",
    "data": {
        "audit_info": {
            "audit_type": "VSR",
            "pdf_filename": "ICCA_Rapport_Test.pdf",
            "organisatie": "Stichting OPSPOOR perceel 1",
            "ter_attentie_van": "Mevr. M. Hubelmeijer",
            "project": "WSP Test Project",
            "rapportnummer": "16166",
            "datum": "2 januari 2025",
            "tijdstip_controle": "09:57",
            "extra_info": "-",
            "controle_uitgevoerd_door": "Hennie Dekker",
            "aanwezig_leverancier": "Louise Rodenhuis",
            "client_logo_url": "http://localhost:3000/assets/logo_header.jpg",
            "controle_datum_lang": "10 februari 2025",
            "locatie_naam": "WSP",
            "locatie_adres": "Utrechtseweg 310 - B5070",
            "locatie_plaats": "Arnhem"
        },
        "categories": [
            {
                "categorie_naam": "Bureaukamer",
                "tel_element": 14,
                "goedkeurgrens": 19,
                "aantal_behaalde_fouten": 1,
                "cijfer": 9.80,
                "beoordeling": "Voldoende"
            },
            {
                "categorie_naam": "Sanitaire ruimte",
                "tel_element": 17,
                "goedkeurgrens": 14,
                "aantal_behaalde_fouten": 4,
                "cijfer": 7.60,
                "beoordeling": "Voldoende"
            },
            {
                "categorie_naam": "Verkeersruimte",
                "tel_element": 9,
                "goedkeurgrens": 9,
                "aantal_behaalde_fouten": 10,
                "cijfer": 7.90,
                "beoordeling": "Voldoende"
            },
            {
                "categorie_naam": "Vergaderzaal",
                "tel_element": 9,
                "goedkeurgrens": 9,
                "aantal_behaalde_fouten": 2,
                "cijfer": 8.50,
                "beoordeling": "Voldoende"
            }
        ],
        "historisch_verloop": [
            { "datum": "5-jan-24", "auditcode": "13739", "cijfer": 9.97 },
            { "datum": "12-apr-24", "auditcode": "14349", "cijfer": 7.37 },
            { "datum": "12-aug-24", "auditcode": "14733", "cijfer": 7.33 },
            { "datum": "15-nov-24", "auditcode": "15001", "cijfer": 8.20 }
        ],
        "foutsoorten": [
            { "lijn1": "Niet", "lijn2": "gehecht", "lijn3": "vuil licht stof", "aantal": 2, "type": "dagelijks" },
            { "lijn1": "Niet", "lijn2": "gehecht", "lijn3": "vuil methode", "aantal": 0, "type": "dagelijks" },
            { "lijn1": "Aanslag", "lijn2": "", "lijn3": "", "aantal": 4, "type": "cumulatief" },
            { "lijn1": "Dicht stof", "lijn2": "", "lijn3": "", "aantal": 0, "type": "cumulatief" },
            { "lijn1": "Gehecht", "lijn2": "vuil", "lijn3": "methode", "aantal": 0, "type": "cumulatief" },
            { "lijn1": "Gehecht", "lijn2": "vuil vlek", "lijn3": "vingertast", "aantal": 0, "type": "cumulatief" },
            { "lijn1": "Niet", "lijn2": "aangevuld", "lijn3": "", "aantal": 1, "type": "divers" },
            { "lijn1": "Niet", "lijn2": "geleegd", "lijn3": "", "aantal": 0, "type": "divers" },
            { "lijn1": "Spinrag", "lijn2": "", "lijn3": "", "aantal": 10, "type": "divers" }
        ],
        "max_fouten": 10,
        "verhouding": {
            "dagelijkse_pct": 33.3,
            "cumulatief_pct": 66.7,
            "diverse_pct": 0.0
        },
        "ruimte_opmerkingen": [
            { "ruimte_nr": "Bg - Dou.Heren", "categorie": "Sanitaire ruimte", "element": "douche installatie", "vuilsoort": "aanslag", "opmerking": "", "aantal_fouten": 2, "foto_nr": "" },
            { "ruimte_nr": "Bg - Ent.Entree", "categorie": "Verkeersruimte", "element": "Test", "vuilsoort": "spinrag", "opmerking": "", "aantal_fouten": 1, "foto_nr": "" },
            { "ruimte_nr": "1e - Kantine", "categorie": "Bureaukamer", "element": "bureau", "vuilsoort": "stof", "opmerking": "Extra aandacht nodig", "aantal_fouten": 3, "foto_nr": "1" },
            { "ruimte_nr": "2e - Vergaderzaal", "categorie": "Bureaukamer", "element": "tafel", "vuilsoort": "vlek", "opmerking": "", "aantal_fouten": 1, "foto_nr": "" },
            { "ruimte_nr": "Bg - Toilet Dames", "categorie": "Sanitaire ruimte", "element": "wastafel", "vuilsoort": "kalk", "opmerking": "Regelmatig ontkalken", "aantal_fouten": 2, "foto_nr": "2" }
        ],
        "element_fotos": [
            { "foto_nummer": 1, "url": "http://localhost:3000/assets/logo_header.jpg" },
            { "foto_nummer": 2, "url": "http://localhost:3000/assets/logo_header.jpg" },
            { "foto_nummer": 3, "url": "http://localhost:3000/assets/logo_header.jpg" },
            { "foto_nummer": 4, "url": "http://localhost:3000/assets/logo_header.jpg" },
            { "foto_nummer": 5, "url": "http://localhost:3000/assets/logo_header.jpg" },
            { "foto_nummer": 6, "url": "http://localhost:3000/assets/logo_header.jpg" },
            { "foto_nummer": 7, "url": "http://localhost:3000/assets/logo_header.jpg" },
            { "foto_nummer": 8, "url": "http://localhost:3000/assets/logo_header.jpg" },
            { "foto_nummer": 9, "url": "http://localhost:3000/assets/logo_header.jpg" }
        ],                
        "technische_aspecten_fotos": [
            { "url": "http://localhost:3000/assets/logo_header.jpg", "beschrijving": "3e-Bur.Nvt: Lichte stof en haren op de liggende delen vd tafelpoten." },
            { "url": "http://localhost:3000/assets/logo_header.jpg", "beschrijving": "3e-Per.Grote groepsruimte: Spinrag en vliegjes op de raamkozijnen." },
            { "url": "http://localhost:3000/assets/logo_header.jpg", "beschrijving": "3e-gro.Nvt: Wat losliggende aarde." },
            { "url": "http://localhost:3000/assets/logo_header.jpg", "beschrijving": "3e-Toi.Nvt: Stoflaag op de bovenste legplank in toilet." },
            { "url": "http://localhost:3000/assets/logo_header.jpg", "beschrijving": "2e-Bur.Kantoor: Vuil op vensterbank." },
            { "url": "http://localhost:3000/assets/logo_header.jpg", "beschrijving": "1e-San.Toilet: Kalk op de kraan." },
            { "url": "http://localhost:3000/assets/logo_header.jpg", "beschrijving": "Bg-Ent.Entree: Voetstappen op vloer." }
        ],
        "algemene_opmerkingen": [
            { "ruimtenummer": "3e-Per.Grote groepsruimte", "opmerkingen": "Wat lichte stof en vervuiling op de moeilijker bereikbare plaatsen." },
            { "ruimtenummer": "2e-Bur.Kantoor", "opmerkingen": "Vensterbanken vragen extra aandacht." },
            { "ruimtenummer": "Bg-Ent.Entree", "opmerkingen": "Voetstappen op vloer bij ingang." }
        ],
        "overige_hygiene_aspecten": [
            { "algemeen": "03. Periodiek vloeronderhoud uitgevoerd", "status": "N.v.t.", "opmerkingen": "" },
            { "algemeen": "01. Aanwezigheid/status logboek", "status": "Onvoldoende", "opmerkingen": "Tijdens controle waren 5 medewerksters aan het werk." },
            { "algemeen": "04. Binnenzijde koelkast", "status": "N.v.t.", "opmerkingen": "" },
            { "algemeen": "02. Uitstraling van de werkkast", "status": "Voldoende", "opmerkingen": "" }
        ]
    }
    }
    ]');
      dbms_output.put_line('  JSON data: '
                           || dbms_lob.getlength(l_json_data) || ' bytes');

        -- Call PDF service directly
      l_url := c_pdf_service_url || c_endpoint_template;
      dbms_output.put_line('  URL: ' || l_url);
        
        -- reset headers
      apex_web_service.g_request_headers.delete;
      apex_web_service.g_request_headers(1).name := 'Content-Type';
      apex_web_service.g_request_headers(1).value := 'application/json; charset=UTF-8';
        
        -- make request
      l_pdf_blob := apex_web_service.make_rest_request_b(
         p_url         => l_url,
         p_http_method => 'POST',
         p_body        => l_json_data
      );

      l_response_code := apex_web_service.g_status_code;
      dbms_output.put_line('  Response code: ' || l_response_code);
      if l_response_code != 200 then
         dbms_output.put_line('  ERROR: HTTP ' || l_response_code);
         raise_application_error(
            -20015,
            'PDF service error: HTTP ' || l_response_code
         );
      end if;

      if l_pdf_blob is null
      or dbms_lob.getlength(l_pdf_blob) < 100 then
         dbms_output.put_line('  ERROR: PDF te klein of leeg');
         raise_application_error(
            -20016,
            'PDF generation failed: response te klein'
         );
      end if;

      dbms_output.put_line('  PDF ontvangen: '
                           || dbms_lob.getlength(l_pdf_blob) || ' bytes');
      dbms_output.put_line('');
      dbms_output.put_line('========================================');
      dbms_output.put_line('Test SUCCESVOL!');
      dbms_output.put_line('========================================');
      return l_pdf_blob;
   exception
      when others then
         apex_debug.error(
            'Error in f_test_icca_rapport_dummy: %s',
            sqlerrm
         );
         dbms_output.put_line('');
         dbms_output.put_line('========================================');
         dbms_output.put_line('ERROR!');
         dbms_output.put_line('========================================');
         dbms_output.put_line('Error: ' || sqlerrm);
         dbms_output.put_line('');
         dbms_output.put_line('Mogelijke oorzaken:');
         dbms_output.put_line('  1. Node.js service draait niet');
         dbms_output.put_line('  2. Template ICCA_RAPPORT niet gevonden');
         dbms_output.put_line('  3. Template syntax error');
         dbms_output.put_line('  4. JSON data formaat incorrect');
         raise;
   end f_test_icca_rapport_dummy;

    --
    -- Test: genereer PDF met volledige dummy data (Fase Control)
    -- Standalone test met hardcoded JSON (zelfde als ICCA maar andere template)
    --
   function f_test_fase_control_dummy return blob is
      l_pdf_blob      blob;
      l_json_data     clob;
      l_url           varchar2(500);
      l_response_code number;
   begin
      apex_debug.message('f_test_fase_control_dummy: start');
      dbms_output.put_line('========================================');
      dbms_output.put_line('Template PDF Test - Fase Control Dummy');
      dbms_output.put_line('========================================');
      dbms_output.put_line('');

    -- Init JSON data (zelfde als ICCA maar met FASE_CONTROL template)
      l_json_data := to_clob(q'[
    {
    "template_name": "FASE_CONTROL",
    "data": {
        "audit_info": {
            "audit_type": "VSR",
            "pdf_filename": "Fase_Control_Test.pdf",
            "organisatie": "Stichting OPSPOOR perceel 1",
            "ter_attentie_van": "Mevr. M. Hubelmeijer",
            "project": "WSP Test Project",
            "rapportnummer": "16166",
            "datum": "2 januari 2025",
            "tijdstip_controle": "09:57",
            "extra_info": "-",
            "controle_uitgevoerd_door": "Hennie Dekker",
            "aanwezig_leverancier": "Louise Rodenhuis",
            "client_logo_url": "http://localhost:3000/assets/logo_header.jpg",
            "controle_datum_lang": "10 februari 2025",
            "locatie_naam": "WSP",
            "locatie_adres": "Utrechtseweg 310 - B5070",
            "locatie_plaats": "Arnhem"
        },
        "categories": [
            {
                "categorie_naam": "Bureaukamer",
                "tel_element": 14,
                "goedkeurgrens": 19,
                "aantal_behaalde_fouten": 1,
                "cijfer": 9.80,
                "beoordeling": "Voldoende"
            },
            {
                "categorie_naam": "Sanitaire ruimte",
                "tel_element": 17,
                "goedkeurgrens": 14,
                "aantal_behaalde_fouten": 4,
                "cijfer": 7.60,
                "beoordeling": "Voldoende"
            },
            {
                "categorie_naam": "Verkeersruimte",
                "tel_element": 9,
                "goedkeurgrens": 9,
                "aantal_behaalde_fouten": 10,
                "cijfer": 7.90,
                "beoordeling": "Voldoende"
            }
        ],
        "historisch_verloop": [
            { "datum": "5-jan-24", "auditcode": "13739", "cijfer": 9.97 },
            { "datum": "12-apr-24", "auditcode": "14349", "cijfer": 7.37 },
            { "datum": "12-aug-24", "auditcode": "14733", "cijfer": 7.33 }
        ],
        "foutsoorten": [
            { "lijn1": "Niet", "lijn2": "gehecht", "lijn3": "vuil licht stof", "aantal": 2, "type": "dagelijks" },
            { "lijn1": "Niet", "lijn2": "gehecht", "lijn3": "vuil methode", "aantal": 0, "type": "dagelijks" },
            { "lijn1": "Aanslag", "lijn2": "", "lijn3": "", "aantal": 4, "type": "cumulatief" },
            { "lijn1": "Dicht stof", "lijn2": "", "lijn3": "", "aantal": 0, "type": "cumulatief" },
            { "lijn1": "Gehecht", "lijn2": "vuil", "lijn3": "methode", "aantal": 0, "type": "cumulatief" },
            { "lijn1": "Gehecht", "lijn2": "vuil vlek", "lijn3": "vingertast", "aantal": 0, "type": "cumulatief" },
            { "lijn1": "Niet", "lijn2": "aangevuld", "lijn3": "", "aantal": 1, "type": "divers" },
            { "lijn1": "Niet", "lijn2": "geleegd", "lijn3": "", "aantal": 0, "type": "divers" },
            { "lijn1": "Spinrag", "lijn2": "", "lijn3": "", "aantal": 10, "type": "divers" }
        ],
        "max_fouten": 10,
        "verhouding": {
            "dagelijkse_pct": 33.3,
            "cumulatief_pct": 66.7,
            "diverse_pct": 0.0
        },
        "ruimte_opmerkingen": [
            { "ruimte_nr": "Bg - Dou.Heren", "categorie": "Sanitaire ruimte", "element": "douche installatie", "vuilsoort": "aanslag", "opmerking": "", "aantal_fouten": 2, "foto_nr": "" },
            { "ruimte_nr": "Bg - Ent.Entree", "categorie": "Verkeersruimte", "element": "Test", "vuilsoort": "spinrag", "opmerking": "", "aantal_fouten": 1, "foto_nr": "" }
        ],
        "element_fotos": [
            { "foto_nummer": 1, "url": "http://localhost:3000/assets/logo_header.jpg" },
            { "foto_nummer": 2, "url": "http://localhost:3000/assets/logo_header.jpg" }
        ],                
        "technische_aspecten_fotos": [
            { "url": "http://localhost:3000/assets/logo_header.jpg", "beschrijving": "Test beschrijving voor technisch aspect." }
        ],
        "algemene_opmerkingen": [
            { "ruimtenummer": "3e-Per.Grote groepsruimte", "opmerkingen": "Test algemene opmerking." }
        ],
        "overige_hygiene_aspecten": [
            { "algemeen": "01. Aanwezigheid/status logboek", "status": "Voldoende", "opmerkingen": "" }
        ]
    }
    }
    ]');
      dbms_output.put_line('  JSON data: '
                           || dbms_lob.getlength(l_json_data) || ' bytes');

        -- Call PDF service directly
      l_url := c_pdf_service_url || c_endpoint_template;
      dbms_output.put_line('  URL: ' || l_url);
        
        -- reset headers
      apex_web_service.g_request_headers.delete;
      apex_web_service.g_request_headers(1).name := 'Content-Type';
      apex_web_service.g_request_headers(1).value := 'application/json; charset=UTF-8';
        
        -- make request
      l_pdf_blob := apex_web_service.make_rest_request_b(
         p_url         => l_url,
         p_http_method => 'POST',
         p_body        => l_json_data
      );

      l_response_code := apex_web_service.g_status_code;
      dbms_output.put_line('  Response code: ' || l_response_code);
      if l_response_code != 200 then
         dbms_output.put_line('  ERROR: HTTP ' || l_response_code);
         raise_application_error(
            -20017,
            'PDF service error: HTTP ' || l_response_code
         );
      end if;

      if l_pdf_blob is null
      or dbms_lob.getlength(l_pdf_blob) < 100 then
         dbms_output.put_line('  ERROR: PDF te klein of leeg');
         raise_application_error(
            -20018,
            'PDF generation failed: response te klein'
         );
      end if;

      dbms_output.put_line('  PDF ontvangen: '
                           || dbms_lob.getlength(l_pdf_blob) || ' bytes');
      dbms_output.put_line('');
      dbms_output.put_line('========================================');
      dbms_output.put_line('Test SUCCESVOL!');
      dbms_output.put_line('========================================');
      return l_pdf_blob;
   exception
      when others then
         apex_debug.error(
            'Error in f_test_fase_control_dummy: %s',
            sqlerrm
         );
         dbms_output.put_line('');
         dbms_output.put_line('========================================');
         dbms_output.put_line('ERROR!');
         dbms_output.put_line('========================================');
         dbms_output.put_line('Error: ' || sqlerrm);
         dbms_output.put_line('');
         dbms_output.put_line('Mogelijke oorzaken:');
         dbms_output.put_line('  1. Node.js service draait niet');
         dbms_output.put_line('  2. Template FASE_CONTROL niet gevonden');
         dbms_output.put_line('  3. Template syntax error');
         dbms_output.put_line('  4. JSON data formaat incorrect');
         raise;
   end f_test_fase_control_dummy;

    --
    -- Test: genereer PDF met volledige dummy data (ICCA Zonder Cijfers)
    -- Standalone test met hardcoded JSON (zonder historisch_verloop)
    --
   function f_test_icca_zonder_cijfers_dummy return blob is
      l_pdf_blob      blob;
      l_json_data     clob;
      l_url           varchar2(500);
      l_response_code number;
   begin
      apex_debug.message('f_test_icca_zonder_cijfers_dummy: start');
      dbms_output.put_line('========================================');
      dbms_output.put_line('Template PDF Test - ICCA Zonder Cijfers Dummy');
      dbms_output.put_line('========================================');
      dbms_output.put_line('');

    -- Init JSON data (hardcoded - ZONDER historisch_verloop)
      l_json_data := to_clob(q'[
    {
    "template_name": "ICCA_ZONDER_CIJFERS",
    "data": {
        "audit_info": {
            "audit_type": "VSR",
            "pdf_filename": "ICCA_Zonder_Cijfers_Test.pdf",
            "organisatie": "Stichting OPSPOOR perceel 1",
            "ter_attentie_van": "Mevr. M. Hubelmeijer",
            "project": "WSP Test Project",
            "rapportnummer": "16166",
            "datum": "2 januari 2025",
            "tijdstip_controle": "09:57",
            "extra_info": "-",
            "controle_uitgevoerd_door": "Hennie Dekker",
            "aanwezig_leverancier": "Louise Rodenhuis",
            "client_logo_url": "http://localhost:3000/assets/logo_header.jpg",
            "controle_datum_lang": "10 februari 2025",
            "locatie_naam": "WSP",
            "locatie_adres": "Utrechtseweg 310 - B5070",
            "locatie_plaats": "Arnhem"
        },
        "categories": [
            {
                "categorie_naam": "Bureaukamer",
                "tel_element": 14,
                "goedkeurgrens": 19,
                "aantal_behaalde_fouten": 1,
                "beoordeling": "Voldoende"
            },
            {
                "categorie_naam": "Sanitaire ruimte",
                "tel_element": 17,
                "goedkeurgrens": 14,
                "aantal_behaalde_fouten": 4,
                "beoordeling": "Voldoende"
            },
            {
                "categorie_naam": "Verkeersruimte",
                "tel_element": 9,
                "goedkeurgrens": 9,
                "aantal_behaalde_fouten": 10,
                "beoordeling": "Onvoldoende"
            },
            {
                "categorie_naam": "Vergaderzaal",
                "tel_element": 12,
                "goedkeurgrens": 15,
                "aantal_behaalde_fouten": 2,
                "beoordeling": "Voldoende"
            }
        ],
        "foutsoorten": [
            { "lijn1": "Niet", "lijn2": "gehecht", "lijn3": "vuil licht stof", "aantal": 2, "type": "dagelijks" },
            { "lijn1": "Niet", "lijn2": "gehecht", "lijn3": "vuil methode", "aantal": 0, "type": "dagelijks" },
            { "lijn1": "Aanslag", "lijn2": "", "lijn3": "", "aantal": 4, "type": "cumulatief" },
            { "lijn1": "Dicht stof", "lijn2": "", "lijn3": "", "aantal": 0, "type": "cumulatief" },
            { "lijn1": "Gehecht", "lijn2": "vuil", "lijn3": "methode", "aantal": 0, "type": "cumulatief" },
            { "lijn1": "Gehecht", "lijn2": "vuil vlek", "lijn3": "vingertast", "aantal": 0, "type": "cumulatief" },
            { "lijn1": "Niet", "lijn2": "aangevuld", "lijn3": "", "aantal": 1, "type": "divers" },
            { "lijn1": "Niet", "lijn2": "geleegd", "lijn3": "", "aantal": 0, "type": "divers" },
            { "lijn1": "Spinrag", "lijn2": "", "lijn3": "", "aantal": 10, "type": "divers" }
        ],
        "max_fouten": 10,
        "verhouding": {
            "dagelijkse_pct": 33.3,
            "cumulatief_pct": 66.7,
            "diverse_pct": 0.0
        },
        "ruimte_opmerkingen": [
            { "ruimte_nr": "Bg - Dou.Heren", "categorie": "Sanitaire ruimte", "element": "douche installatie", "vuilsoort": "aanslag", "opmerking": "", "aantal_fouten": 2, "foto_nr": "" },
            { "ruimte_nr": "Bg - Ent.Entree", "categorie": "Verkeersruimte", "element": "Test", "vuilsoort": "spinrag", "opmerking": "", "aantal_fouten": 1, "foto_nr": "" }
        ],
        "element_fotos": [
            { "foto_nummer": 1, "url": "http://localhost:3000/assets/logo_header.jpg" },
            { "foto_nummer": 2, "url": "http://localhost:3000/assets/logo_header.jpg" }
        ],                
        "technische_aspecten_fotos": [
            { "url": "http://localhost:3000/assets/logo_header.jpg", "beschrijving": "Test beschrijving voor technisch aspect." }
        ],
        "algemene_opmerkingen": [
            { "ruimtenummer": "3e-Per.Grote groepsruimte", "opmerkingen": "Test algemene opmerking." }
        ],
        "overige_hygiene_aspecten": [
            { "algemeen": "01. Aanwezigheid/status logboek", "status": "Voldoende", "opmerkingen": "" }
        ]
    }
    }
    ]');
      dbms_output.put_line('  JSON data: '
                           || dbms_lob.getlength(l_json_data) || ' bytes');

        -- Call PDF service directly
      l_url := c_pdf_service_url || c_endpoint_template;
      dbms_output.put_line('  URL: ' || l_url);
        
        -- reset headers
      apex_web_service.g_request_headers.delete;
      apex_web_service.g_request_headers(1).name := 'Content-Type';
      apex_web_service.g_request_headers(1).value := 'application/json; charset=UTF-8';
        
        -- make request
      l_pdf_blob := apex_web_service.make_rest_request_b(
         p_url         => l_url,
         p_http_method => 'POST',
         p_body        => l_json_data
      );

      l_response_code := apex_web_service.g_status_code;
      dbms_output.put_line('  Response code: ' || l_response_code);
      if l_response_code != 200 then
         dbms_output.put_line('  ERROR: HTTP ' || l_response_code);
         raise_application_error(
            -20019,
            'PDF service error: HTTP ' || l_response_code
         );
      end if;

      if l_pdf_blob is null
      or dbms_lob.getlength(l_pdf_blob) < 100 then
         dbms_output.put_line('  ERROR: PDF te klein of leeg');
         raise_application_error(
            -20020,
            'PDF generation failed: response te klein'
         );
      end if;

      dbms_output.put_line('  PDF ontvangen: '
                           || dbms_lob.getlength(l_pdf_blob) || ' bytes');
      dbms_output.put_line('');
      dbms_output.put_line('========================================');
      dbms_output.put_line('Test SUCCESVOL!');
      dbms_output.put_line('========================================');
      return l_pdf_blob;
   exception
      when others then
         apex_debug.error(
            'Error in f_test_icca_zonder_cijfers_dummy: %s',
            sqlerrm
         );
         dbms_output.put_line('');
         dbms_output.put_line('========================================');
         dbms_output.put_line('ERROR!');
         dbms_output.put_line('========================================');
         dbms_output.put_line('Error: ' || sqlerrm);
         dbms_output.put_line('');
         dbms_output.put_line('Mogelijke oorzaken:');
         dbms_output.put_line('  1. Node.js service draait niet');
         dbms_output.put_line('  2. Template ICCA_ZONDER_CIJFERS niet gevonden');
         dbms_output.put_line('  3. Template syntax error');
         dbms_output.put_line('  4. JSON data formaat incorrect');
         raise;
   end f_test_icca_zonder_cijfers_dummy;

end icca_pdf_generator;
/