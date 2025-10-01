set define off verify off feedback off

create or replace package aop_api25_pkg
AUTHID CURRENT_USER
as

/* Copyright 2015-2025 - APEX RnD - United Codes
*/

--## CONSTANTS
 
--### AOP Version
-- The version of APEX Office Print (AOP)
c_aop_version               constant varchar2(6 char)  := '25.1.2';                               

--### AOP URLs
-- The default url for the AOP Server
c_aop_url                   constant varchar2(50 char) := 'http://api.apexofficeprint.com/';      
-- The default url for the AOP Fallback Server in case the c_aop_url would fail
c_aop_url_fallback          constant varchar2(50 char) := 'https://api-eu.apexofficeprint.com/'; 
-- The default secure url for the AOP Server
c_aop_url_secure            constant varchar2(50 char) := 'https://api.apexofficeprint.com/';     
-- The default secure url for the AOP Fallback Server
c_aop_url_secure_fallback   constant varchar2(50 char) := 'https://api-eu.apexofficeprint.com/';
-- The url for the AOP Server in the Oracle Cloud US (Ashburn)
c_aop_url_oci_us            constant varchar2(50 char) := 'https://api-us.apexofficeprint.com/';  
-- The url for the AOP Server in the Oracle Cloud EU (Frankfurt)
c_aop_url_oci_eu            constant varchar2(50 char) := 'https://api-eu.apexofficeprint.com/';  
-- The url for the AOP Server in the Oracle Cloud APAC (Hyperdad)
c_aop_url_oci_apac          constant varchar2(50 char) := 'https://api-apac.apexofficeprint.com/';

--### Available constants
--### Template and Data Type
c_source_type_apex          constant varchar2(4 char)  := 'APEX';           -- Template Type
c_source_type_workspace     constant varchar2(9 char)  := 'WORKSPACE';      -- Template Type
c_source_type_sql           constant varchar2(3 char)  := 'SQL';            -- Template and Data Type
c_source_type_plsql_sql     constant varchar2(9 char)  := 'PLSQL_SQL';      -- Template and Data Type
c_source_type_plsql         constant varchar2(5 char)  := 'PLSQL';          -- Template and Data Type
c_source_type_url           constant varchar2(3 char)  := 'URL';            -- Template and Data Type
c_source_type_url_aop       constant varchar2(7 char)  := 'URL_AOP';        -- Template Type
c_source_type_rpt           constant varchar2(6 char)  := 'IR';             -- Data Type
c_source_type_xml           constant varchar2(3 char)  := 'XML';            -- Data Type
c_source_type_json          constant varchar2(4 char)  := 'JSON';           -- Template and Data Type
c_source_type_json_files    constant varchar2(10 char) := 'JSON_FILES';     -- Data Type
c_source_type_refcursor     constant varchar2(9 char)  := 'REFCURSOR';      -- Data Type
c_source_type_sql_array     constant varchar2(9 char)  := 'SQL_ARRAY';      -- Data Type
c_source_type_filename      constant varchar2(8 char)  := 'FILENAME';       -- Template Type
c_source_type_db_directory  constant varchar2(12 char) := 'DB_DIRECTORY';   -- Template Type
c_source_type_aop_report    constant varchar2(10 char) := 'AOP_REPORT';     -- Template Type
c_source_type_apex_report   constant varchar2(11 char) := 'APEX_REPORT';    -- Template Type
c_source_type_apex_report_do constant varchar2(14 char):= 'APEX_REPORT_DO'; -- Template Type
c_source_type_layouts       constant varchar2(14 char) := 'REPORT_LAYOUTS'; -- Template Type
c_source_type_aop_template  constant varchar2(1 char)  := null;             -- Template Type
c_source_type_clob_base64   constant varchar2(11 char) := 'CLOB_BASE64';    -- Template Type
c_source_type_oci_objs      constant varchar2(8 char)  := 'OCI_OBJS';       -- Template Type
c_source_type_none          constant varchar2(4 char)  := 'NONE';           -- Template and Data Type
--### Converter
c_source_type_converter     constant varchar2(9 char)  := 'CONVERTER';
--### Mime Type
c_mime_type_docx            constant varchar2(71 char) := 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
c_mime_type_xlsx            constant varchar2(65 char) := 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
c_mime_type_pptx            constant varchar2(73 char) := 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
c_mime_type_doc             constant varchar2(71 char) := 'application/msword';
c_mime_type_xls             constant varchar2(71 char) := 'application/vnd.ms-excel';
c_mime_type_ppt             constant varchar2(71 char) := 'application/vnd.ms-powerpoint';
c_mime_type_odt             constant varchar2(39 char) := 'application/vnd.oasis.opendocument.text';
c_mime_type_ods             constant varchar2(46 char) := 'application/vnd.oasis.opendocument.spreadsheet';
c_mime_type_odp             constant varchar2(47 char) := 'application/vnd.oasis.opendocument.presentation';
c_mime_type_pdf             constant varchar2(15 char) := 'application/pdf';
c_mime_type_html            constant varchar2(9 char)  := 'text/html';
c_mime_type_markdown        constant varchar2(13 char) := 'text/markdown';
c_mime_type_rtf             constant varchar2(15 char) := 'application/rtf';
c_mime_type_json            constant varchar2(16 char) := 'application/json';
c_mime_type_xml             constant varchar2(15 char) := 'application/xml';
c_mime_type_text            constant varchar2(10 char) := 'text/plain';
c_mime_type_csv             constant varchar2(10 char) := 'text/csv';
c_mime_type_png             constant varchar2(9 char)  := 'image/png';
c_mime_type_jpg             constant varchar2(10 char) := 'image/jpeg';
c_mime_type_gif             constant varchar2(9 char)  := 'image/gif';
c_mime_type_bmp             constant varchar2(9 char)  := 'image/bmp';
c_mime_type_msbmp           constant varchar2(19 char) := 'image/x-windows-bmp';
c_mime_type_docm            constant varchar2(48 char) := 'application/vnd.ms-word.document.macroenabled.12';
c_mime_type_xlsm            constant varchar2(46 char) := 'application/vnd.ms-excel.sheet.macroenabled.12';
c_mime_type_pptm            constant varchar2(58 char) := 'application/vnd.ms-powerpoint.presentation.macroenabled.12';
c_mime_type_ics             constant varchar2(13 char) := 'text/calendar';
c_mime_type_ifb             constant varchar2(13 char) := 'text/calendar';
c_mime_type_eml             constant varchar2(14 char) := 'message/rfc822';
c_mime_type_msg             constant varchar2(26 char) := 'application/vnd.ms-outlook';
c_mime_type_zip             constant varchar2(26 char) := 'application/zip';
--### Calender Type
c_cal_month                 constant varchar2(19 char) := 'month';
c_cal_week                  constant varchar2(19 char) := 'week';
c_cal_day                   constant varchar2(19 char) := 'day';
c_cal_list                  constant varchar2(19 char) := 'list';
--### Output Encoding
c_output_encoding_raw       constant varchar2(3 char)  := 'raw';
c_output_encoding_base64    constant varchar2(6 char)  := 'base64';
--### Output Type
c_word_docx                 constant varchar2(4 char)  := 'docx';
c_excel_xlsx                constant varchar2(4 char)  := 'xlsx';
c_powerpoint_pptx           constant varchar2(4 char)  := 'pptx'; 
c_opendocument_odt          constant varchar2(3 char)  := 'odt';
c_opendocument_ods          constant varchar2(3 char)  := 'ods';
c_opendocument_odp          constant varchar2(3 char)  := 'odp'; 
c_word_doc                  constant varchar2(3 char)  := 'doc';
c_excel_xls                 constant varchar2(3 char)  := 'xls';
c_powerpoint_ppt            constant varchar2(3 char)  := 'ppt'; 
c_pdf_pdf                   constant varchar2(3 char)  := 'pdf'; 
c_html_html                 constant varchar2(4 char)  := 'html';
c_markdown_md               constant varchar2(2 char)  := 'md';
c_text_txt                  constant varchar2(3 char)  := 'txt'; 
c_csv_csv                   constant varchar2(3 char)  := 'csv'; 
c_word_rtf                  constant varchar2(3 char)  := 'rtf';
c_word_macro_docm           constant varchar2(4 char)  := 'docm';
c_excel_macro_xlsm          constant varchar2(4 char)  := 'xlsm';
c_powerpoint_macro_pptm     constant varchar2(4 char)  := 'pptm'; 
c_calendar_ics              constant varchar2(3 char)  := 'ics';
c_calendar_ifb              constant varchar2(3 char)  := 'ifb';
c_json_json                 constant varchar2(4 char)  := 'json';
c_xml_xml                   constant varchar2(3 char)  := 'xml';
c_email_eml                 constant varchar2(3 char)  := 'eml';  
c_email_msg                 constant varchar2(3 char)  := 'msg';  
c_zip_zip                   constant varchar2(3 char)  := 'zip';  
c_image_jpg                 constant varchar2(3 char)  := 'jpg';
c_image_jpeg                constant varchar2(4 char)  := 'jpeg';
c_image_gif                 constant varchar2(3 char)  := 'gif';
c_image_png                 constant varchar2(3 char)  := 'png';
c_image_bmp                 constant varchar2(3 char)  := 'bmp';
c_onepagepdf_pdf            constant varchar2(10 char) := 'onepagepdf';
c_count_tags                constant varchar2(10 char) := 'count_tags';
c_get_attachments           constant varchar2(16 char) := 'get_attachments';
c_xfa_form_fields           constant varchar2(16 char) := 'xfa_form_fields';
c_form_fields               constant varchar2(11 char) := 'form_fields';
c_validate_pdf              constant varchar2(12 char) := 'validate_pdf';
c_defined_by_apex_item      constant varchar2(9 char)  := 'apex_item';
c_converter                 constant varchar2(9 char)  := 'converter';
c_aopreport                 constant varchar2(9 char)  := 'aopreport';
c_aoe                       constant varchar2(3 char)  := 'aoe';
--### Output To
c_output_return             constant varchar2(1 char)  := null;
c_output_browser            constant varchar2(7 char)  := 'BROWSER';
c_output_procedure          constant varchar2(9 char)  := 'PROCEDURE';
c_output_procedure_browser  constant varchar2(17 char) := 'PROCEDURE_BROWSER';
c_output_procedure_inline   constant varchar2(17 char) := 'PROCEDURE_INLINE';
c_output_inline             constant varchar2(14 char) := 'BROWSER_INLINE'; 
c_output_directory          constant varchar2(9 char)  := 'DIRECTORY';
c_output_db_directory       constant varchar2(12 char) := 'DB_DIRECTORY';
c_output_cloud              constant varchar2(5 char)  := 'CLOUD';
c_output_async              constant varchar2(5 char)  := 'ASYNC';
c_output_web_service        constant varchar2(12 char) := 'WEB_SERVICE';
c_apex_office_edit          constant varchar2(16 char) := 'APEX_OFFICE_EDIT';
c_pdf_region_pro            constant varchar2(14 char) := 'PDF_REGION_PRO';
--### Special
c_special_number_as_string  constant varchar2(16 char) := 'NUMBER_TO_STRING';
c_special_report_as_label   constant varchar2(16 char) := 'REPORT_AS_LABELS';
c_special_ir_filters_top    constant varchar2(14 char) := 'FILTERS_ON_TOP';
c_special_ir_highlights_top constant varchar2(17 char) := 'HIGHLIGHTS_ON_TOP';
c_special_ir_excel_header_f constant varchar2(18 char) := 'HEADER_WITH_FILTER';
c_special_ir_saved_report   constant varchar2(19 char) := 'ALWAYS_REPORT_ALIAS';
c_special_ir_repeat_header  constant varchar2(13 char) := 'REPEAT_HEADER';
c_obfuscate_data            constant varchar2(14 char) := 'OBFUSCATE_DATA';
--### Debug
c_debug_no                  constant varchar2(3 char)  := 'No';
c_debug_remote              constant varchar2(3 char)  := 'Yes';
c_debug_local               constant varchar2(5 char)  := 'Local';
c_debug_application_item    constant varchar2(9 char)  := 'APEX_ITEM';
--### Converter
c_converter_libreoffice     constant varchar2(7 char)  := 'soffice';            -- LibreOffice 
c_converter_libreoffice_sa  constant varchar2(18 char) := 'soffice-standalone'; -- LibreOffice Standalone
c_converter_msoffice        constant varchar2(11 char) := 'officetopdf';        -- MS Office (only Windows)
c_converter_custom          constant varchar2(7 char)  := 'custom';             -- Custom converter defined in the AOP Server config
--### Mode
c_mode_production           constant varchar2(15 char) := 'production';
c_mode_development          constant varchar2(15 char) := 'development';
--### Supported Languages; used for the translation of IR
c_en                        constant varchar2(5 char)  := 'en';
c_nl                        constant varchar2(5 char)  := 'nl';
c_fr                        constant varchar2(5 char)  := 'fr';
c_de                        constant varchar2(5 char)  := 'de';
--### Strings 
c_init_null                 constant varchar2(5 char)  := 'null;';
c_false                     constant varchar2(5 char)  := 'false';
c_true                      constant varchar2(4 char)  := 'true';
c_yes                       constant varchar2(3 char)  := 'Yes';
c_no                        constant varchar2(2 char)  := 'No';
c_y                         constant varchar2(1 char)  := 'Y';
c_n                         constant varchar2(1 char)  := 'N';
--### Internal Use for conditional compilation - see wwv_flow_imp.sql 
c_apex_050                  constant pls_integer := 20130101;
c_apex_051                  constant pls_integer := 20160824;
c_apex_181                  constant pls_integer := 20180404;
c_apex_182                  constant pls_integer := 20180928;
c_apex_191                  constant pls_integer := 20190331;
c_apex_192                  constant pls_integer := 20191004;
c_apex_201                  constant pls_integer := 20200331;
c_apex_202                  constant pls_integer := 20201001;
c_apex_211                  constant pls_integer := 20210415;
c_apex_212                  constant pls_integer := 20211015;
c_apex_221                  constant pls_integer := 20220412;
c_apex_222                  constant pls_integer := 20221007;
c_apex_231                  constant pls_integer := 20230428;
c_apex_232                  constant pls_integer := 20231031;
c_apex_241                  constant pls_integer := 20240531;
c_apex_242                  constant pls_integer := 20241130;


--## TYPES
type t_query is record (
    name  varchar2(30),
    query varchar2(32767),
    binds wwv_flow_plugin_util.t_bind_list);

type t_query_list is table of t_query index by pls_integer;

c_sql_array t_query_list;

--type t_bind_record is record(name varchar2(100), value varchar2(32767));
--type t_bind_table  is table of t_bind_record index by pls_integer;
c_binds wwv_flow_plugin_util.t_bind_list;

/* Variables */
--## VARIABLES

--### Logger
g_logger_enabled             boolean := true;        -- In case you use Logger (https://github.com/OraOpenSource/Logger), you can compile this package to enable Logger output:
                                                     -- SQL> ALTER PACKAGE aop_api25_pkg COMPILE PLSQL_CCFLAGS = 'logger_on:TRUE';
                                                     -- When compiled and this global variable is set to true, debug will be written to logger too
--### Call to AOP 
g_aop_url                    varchar2(200 char) := null;  -- AOP Server url
g_api_key                    varchar2(50 char)  := null;  -- AOP API Key; only needed when AOP Cloud is used (http(s)://www.apexofficeprint.com/api)
g_aop_mode                   varchar2(15 char)  := null;  -- AOP Mode can be development or production; when running in development no cloud credits are used but a watermark is printed
g_failover_aop_url           varchar2(200 char) := null;  -- AOP Server url in case of failure of AOP url
g_failover_procedure         varchar2(200 char) := null;  -- When the failover url is used, the procedure specified in this variable will be called
g_template_type              varchar2(100 char) := null;  -- Specify the template type (xlsx, docx, ...) in case the filename is not part of the template source (e.g. URL of OneDrive or Object Storage)
g_output_converter           varchar2(50 char)  := null;  -- Set the converter to go to PDF (or other format different from template) e.g. officetopdf, libreoffice or libreoffice-standalone
g_force_converter            boolean            := false;  -- Force the given converter for non Office formats (e.g. md, csv, txt, html)
g_output_locale              varchar2(50 char)  := null;  -- Available when output type is docx, pptx or pdf, sets the locale e.g. en, ne etc. 
g_output_image_resolution    varchar2(50 char)  := null;  -- When using openofficeconverter, set the resolution of the image e.g. 300dpi, 600dpi, 900dpi or 1200dpi 
g_output_jpeg_compression    varchar2(50 char)  := null;  -- When using openofficeconverter, specify the JPEG compression, percentage between 0-100
g_output_convert_to_pdfa     varchar2(50 char)  := null;  -- When using openofficeconverter, specify 1b or 2b which are standard PDF compliant versions, specifying any true value will convert to a PDF/A 1b compliant PDF.
g_output_ua_compliant_pdf    varchar2(50 char)  := null;  -- When using openofficeconverter, specify true to create a PDF/UA compliant PDF
g_output_correct_page_nr     boolean       := false; -- boolean to check for AOPMergePage text to replace it with the page number.
g_output_lock_form           boolean       := false; -- boolean that determines if the pdf forms should be locked/flattened.
g_lock_form_ignoring_sign    boolean       := false; -- boolean that determines to lock/flatten everything in the output PDF but not the signature fields
g_sign_certificate_field     varchar2(100 char) := '';    -- the name of the signature field to sign the output document (optional: invisible signature will be placed otherwise)
g_identify_form_fields       boolean       := false; -- boolean that fills in the name of the fields of a PDF Form in the field itself so it's easy to identify which field is at what position
g_proxy_override             varchar2(300 char) := null;  -- null=proxy defined in the application attributes
g_transfer_timeout           number(6)     := 1800;  -- default of APEX is 180
g_wallet_path                varchar2(300 char) := null;  -- null=defined in Manage Instance > Instance Settings
g_wallet_pwd                 varchar2(300 char) := null;  -- null=defined in Manage Instance > Instance Settings
g_https_host                 varchar2(300 char) := null;  -- The host name to be matched against the common name (CN) of the remote server's certificate for an HTTPS request.
g_apex_web_service_rheader_n2 varchar2(200 char) := null; -- Add a custome request header name when calling the AOP Server. This variable will set: apex_web_service.g_request_headers(2).name
g_apex_web_service_rheader_v2 varchar2(4000 char):= null; -- Add a custome request header value when calling the AOP Server. This variable will set: apex_web_service.g_request_headers(2).value
g_output_filename            varchar2(300 char) := null;  -- output
g_cloud_provider             varchar2(100 char) := null;  -- dropbox, gdrive, onedrive, aws_s3, (s)ftp
g_cloud_location             varchar2(4000 char):= null;  -- directory in dropbox, gdrive, onedrive, aws_s3 (with bucket), (s)ftp
g_cloud_access_token         varchar2(4000 char):= null;  -- access token or credentials for dropbox, gdrive, onedrive, aws_s3, (s)ftp (needs json)
g_language                   varchar2(2 char)   := c_en;  -- Language can be: en, fr, nl, de, used for the translation of filters applied etc. (translation build-in AOP)
g_app_language               varchar2(20 char)  := null;  -- Language specified in the APEX app (primary language, translated language), when left to null, apex_util.get_session_lang is being used
g_logging                    clob          := '';    -- ability to add your own logging: e.g. "request_id":"123", "request_app":"APEX", "request_user":"RND"
g_debug                      varchar2(10 char)  := null;  -- set to 'Local' when only the JSON needs to be generated, 'Remote' for remote debug
g_debug_procedure            varchar2(4000 char):= null;  -- when debug in APEX is turned on, next to the normal APEX debug, this procedure will be called
                                                     --   e.g. to write to your own debug table. The definition of the procedure needs to be the same as aop_debug
g_special                    varchar2(4000 char):= null;  -- Special settings defined in the APEX Plug-in concerning Reports (colon separated), see p_special
g_app_id                     number        := null;  -- APEX application id
g_page_id                    number        := null;  -- APEX page id
g_user_name                  varchar2(200 char) := null;  -- APEX user name (APP_USER)
g_force_create_apex_session  boolean       := false; -- Force creating a new APEX session
g_caller_program             varchar2(2)   := null;  -- Either null or DA (dynamic action)
g_data_source                varchar2(4000):= null;  -- Override p_data_source  
g_ig_selected_pks            varchar2(4000):= null;  -- Override p_ig_selected_pks  

--### APEX Page Items 
g_apex_items                 varchar2(4000 char):= null;  -- colon-separated list of APEX items e.g. P1_X:P1_Y, which can be referenced in a template using {Pxx_ITEM}
                                                     -- you can only use this global variable in combination with reports (classic, IR, IG, ...).
                                                     -- When using a SQL Query, you can define the page item in your SQL query, e.g. :P1_ITEM as "P1_ITEM"
--### Layout for IR  
g_rpt_header_font_name       varchar2(50 char)  := '';    -- Arial - see https://www.microsoft.com/typography/Fonts/product.aspx?PID=163
g_rpt_header_font_size       varchar2(3 char)   := '';    -- 14
g_rpt_header_font_color      varchar2(50 char)  := '';    -- #071626
g_rpt_header_back_color      varchar2(50 char)  := '';    -- #FAFAFA
g_rpt_header_border_width    varchar2(50 char)  := '';    -- 1 ; '0' = no border
g_rpt_header_border_color    varchar2(50 char)  := '';    -- #000000
g_rpt_header_x_margin        varchar2(50 char)  := '';    -- '0'; "1pt"
g_rpt_header_y_margin        varchar2(50 char)  := '';    -- '0'; "1pt"
g_rpt_break_font_color       varchar2(50 char)  := '';    -- #071626
g_rpt_break_back_color       varchar2(50 char)  := '';    -- #FAFAFA
g_rpt_break_show_header      varchar2(1 char)   := null;  -- Show the header again after the break (Y/N)
g_rpt_data_font_name         varchar2(50 char)  := '';    -- Arial - see https://www.microsoft.com/typography/Fonts/product.aspx?PID=163
g_rpt_data_font_size         varchar2(3 char)   := '';    -- 14
g_rpt_data_font_color        varchar2(50 char)  := '';    -- #000000
g_rpt_data_back_color        varchar2(50 char)  := '';    -- #FFFFFF
g_rpt_data_border_width      varchar2(50 char)  := '';    -- 1 ; '0' = no border
g_rpt_data_border_color      varchar2(50 char)  := '';    -- #000000
g_rpt_data_alt_row_color     varchar2(50 char)  := '';    -- #FFFFFF for no alt row color, use same color as g_rpt_data_back_color
g_rpt_data_x_margin        varchar2(50 char)  := '';    -- '0'; "1pt"
g_rpt_data_y_margin        varchar2(50 char)  := '';    -- '0'; "1pt"
g_rpt_group_border_color     varchar2(50 char)  := '';    -- default the same as data and header border color. 
g_rpt_group_border_width     varchar2(50 char)  := '';    -- grouping border size, default 4.
g_rpt_header_vertical_align  varchar2(50 char)  := '';    -- possible values: top, center, bottom
g_rpt_data_vertical_align    varchar2(50 char)  := '';    -- possible values: top, center, bottom
/* see also Printing attributes in Interactive Report */
g_is_component_used_yn       varchar2(1 char)   := null;  -- If you want to override the is_component_used_yn, you can specify 'Y' to always show or 'N' to never show.
g_visible_report_columns     varchar2(4000 char):= null;  -- Colon separated list of classic report, interactive report or interactive grid columns e.g. EMPNO:ENAME,
                                                     -- which will be visible regardless of authorization and condition
g_hidden_report_columns      varchar2(4000 char):= null;  -- Colon separated list of classic report, interactive report or interactive grid columns e.g. EMPNO:ENAME
                                                     -- which will be hidden regardless of authorization and condition
--### Settings for Calendar
g_cal_type                   varchar2(10 char)  := c_cal_month; -- can be month (default), week, day, list; constants can be used
g_start_date                 date          := null;  -- start date of calendar
g_end_date                   date          := null;  -- end date of calendar
g_weekdays                   varchar2(300 char) := null;  -- translation for weekdays e.g. Monday:Tuesday:Wednesday etc.
g_months                     varchar2(300 char) := null;  -- translation for months   e.g. January:February etc.  
g_color_days_sql             varchar2(4000 char):= null;  -- color the background of certain days.
                                                     --   e.g. select 1 as "id", sysdate as "date", 'FF8800' as "color" from dual
g_separate_pages             varchar2(5 char)   := 'false'; -- start calendar on new page (true) or start calendar on same page
g_alignment                  varchar2(5 char)   := 'right'; -- align text on calender: left center or right
g_title_alignment            varchar2(5 char)   := 'right'; -- align title of the calendar: left right or center
g_day_alignment              varchar2(5 char)   := 'right'; -- align days of the calendar: left right or center
g_start_of_week              varchar2(3 char)   := 'Mon';   -- start of the week day: Monday (Mon) or Sunday (Sun)
g_new_row_per_event          varchar2(5 char)   := 'false'; -- show events vertically in new row (true). Show events horizontally in new column (false). Default is false.

--### Call to URL data source
g_url_http_method            varchar2(10 char)  := 'GET';
g_url_username               varchar2(30 char) := null;
g_url_password               varchar2(300 char) := null;
g_url_schema                 varchar2(100 char) := 'Basic';
g_url_proxy_override         varchar2(300 char) := null;
g_url_transfer_timeout       number        := 180;
g_url_body                   clob          := empty_clob();
g_url_body_blob              blob          := empty_blob();
g_url_parm_name              apex_application_global.vc_arr2; --:= empty_vc_arr;
g_url_parm_value             apex_application_global.vc_arr2; --:= empty_vc_arr;
g_url_wallet_path            varchar2(300 char) := null;
g_url_wallet_pwd             varchar2(300 char) := null;
g_url_https_host             varchar2(300 char) := null;  -- parameter for apex_web_service, not used, please apply APEX patch if issues
g_url_credential_static_id   varchar2(300 char) := null;
g_url_token_url              varchar2(300 char) := null;
--### Web Source Module (APEX >= 18.1)
g_web_source_first_row       pls_integer   := null;  -- parameter for apex_exec.open_web_source_query
g_web_source_max_rows        pls_integer   := null;  -- parameter for apex_exec.open_web_source_query
g_web_source_total_row_cnt   boolean       := false; -- parameter for apex_exec.open_web_source_query
--### REST Enabled SQL (APEX >= 18.1)
g_rest_sql_auto_bind_items   boolean       := true;  -- parameter for apex_exec.open_remote_sql_query
g_rest_sql_first_row         pls_integer   := null;  -- parameter for apex_exec.open_remote_sql_query
g_rest_sql_max_rows          pls_integer   := null;  -- parameter for apex_exec.open_remote_sql_query
g_rest_sql_total_row_cnt     boolean       := false; -- parameter for apex_exec.open_remote_sql_query
g_rest_sql_total_row_limit   pls_integer   := null;  -- parameter for apex_exec.open_remote_sql_query
--### Input Data
g_replace_special_symbols    varchar2(5 char)   := null;  -- Option to replace special symbols in the selected columns/keys. Replaces +, -, *, /, and  % by _.
g_override_html_expr_on_null boolean       := false; -- When HTML expressions are being used in reports, but they are null, they can be overwritten to use the report_null_values_as
--### IP Printer support
g_ip_printer_location        varchar2(300 char) := null;
g_ip_printer_version         varchar2(300 char) := '1';
g_ip_printer_requester       varchar2(300 char) := coalesce(apex_application.g_user, USER);
g_ip_printer_job_name        varchar2(300 char) := 'AOP';
g_ip_printer_return_output   varchar2(5 char)   := null; -- null or 'Yes' or 'true'
g_ip_printer_operation_attr  varchar2(4000 char):= null; -- null or as a key value pair
g_ip_printer_job_attr        varchar2(4000 char):= null; -- null or as a key value pair
--### Transformation function
g_transformation_function    varchar2(4000 char):= null; -- Transformation function used for the data manipulation by the AOP Server.
--### AOP Processing
g_pre_conversion_command     varchar2(4000 char):= null; -- The command to execute before the conversion to another file format. This command should be present on aop_config.json file.
g_pre_conversion_command_p   varchar2(4000 char):= null; -- Parameter (in JSON) before the conversion to another file format. These parameters should be present on aop_config.json file.
g_post_conversion_command    varchar2(4000 char):= null; -- The command to execute after the conversion to another file format. This command should be present on aop_config.json file.
g_post_conversion_command_p  varchar2(4000 char):= null; -- Parameter (in JSON) after the conversion to another file format. These parameters should be present on aop_config.json file.
g_post_merge_command         varchar2(4000 char):= null; -- The command to execute after the merge of files. This command should be present on aop_config.json file.
g_post_merge_command_p       varchar2(4000 char):= null; -- Parameter (in JSON) after the merge of files. These parameters should be present on aop_config.json file.
g_pipeline_name              varchar2(4000 char):= null; -- The name of the pipeline that will be executed.
g_post_process_command       varchar2(4000 char):= null; -- The command to execute. This command should be present on aop_config.json file.
g_post_process_command_p     varchar2(4000 char):= null; -- Parameter (in JSON) in the post process command. These parameters should be present on aop_config.json file.
g_post_process_return_output boolean       := true; -- Either to return the output or not. Note this output is AOP's output and not the post process command output.
g_post_process_delete_delay  number(9)     := 1500; -- AOP deletes the file provided to the command directly after executing it. This can be delayed with this option. Integer in milliseconds.
--### AOP Config
g_aop_config                 varchar2(32767):= null; -- AOP config file; anything here will overwrite or extend other attributes in the JSON. Make sure this is valid JSON.
--### Convert characterset 
g_convert                    varchar2(1 char)   := c_n;   -- set to Y (c_y) if you want to convert the JSON that is send over; necessary for Arabic support
g_convert_source_charset     varchar2(20 char)  := null;  -- default of database
g_convert_target_charset     varchar2(20 char)  := 'AL32UTF8';  
g_stop_apex_engine           varchar2(1 char)   := c_n;   -- stop the APEX engine
g_run_with_dbms_scheduler    varchar2(1 char)   := c_n;   -- Run the call in the background through a sys.dbms_scheduler job, when finished call defined procedure. 
--### Output
-- set output directory on AOP Server
-- if . is specified the files are saved in the default directory: outputfiles
g_output_directory           varchar2(200 char) := '.';   
g_return_output              boolean            := false; -- Either to return the output or not in case of output directory.
g_output_sign_certificate    varchar2(32000 char):= null; -- sign PDF with signature which is base64 encoded
g_output_sign_certificate_pwd varchar2(500 char):= null;  -- sign PDF with password
g_output_sign_certificate_fld varchar2(500 char):= null;  -- sign PDF with the given signature field name
g_output_sign_certificate_img varchar2(32767 char):= null;-- sign PDF with the given base64 encoded image as background for visible signature
g_output_sign_certificate_txt varchar2(500 char):= null;  -- sign PDF with the given text to display on the signature
g_output_sign_certificate_prp varchar2(32767 char):= null;-- sign PDF with the certificate privatekey password
g_output_split               varchar2(5 char)   := null;  -- split file: one file per page: true/false
g_output_split_by_page       number             := null;  -- split file: one file per page: 1, 2, 3, ...
g_output_split_by_string     varchar2(500 char) := null;  -- split file: by string present on the page: e.g. "Invoice No" or "Invoice No || Invoice Number"
g_output_split_after_string  boolean            := false; -- -- split file: split_by_string's default behavior is to split the pages before the page in which the string is found, and start a new pdf, use this option if you want to split the pages after the page in which the string is found 
g_output_merge               varchar2(5 char)   := null;  -- merge files into one PDF true/false
g_output_icon_font           varchar2(20 char)  := null;  -- the icon font to use for the output, Font-APEX or Font Awesome 5 (default)
g_output_even_page           varchar2(5 char)   := null;  -- PDF option to always print even pages (necessary for two-sided pages): true/false
g_output_merge_making_even   varchar2(5 char)   := null;  -- PDF option to merge making all documents even paged (necessary for two-sided pages): true/false
g_output_page_margin         varchar2(200 char) := null;  -- HTML to PDF option: margin in px, can also add top, bottom, left, right
g_output_page_orientation    varchar2(10 char)  := null;  -- HTML to PDF option: portrait (default) or landscape
g_output_page_width          varchar2(10 char)  := null;  -- HTML to PDF option: width in px, mm, cm, in. No unit means px.
g_output_page_height         varchar2(10 char)  := null;  -- HTML to PDF option: height in px, mm, cm, in. No unit means px.
g_output_page_format         varchar2(10 char)  := null;  -- HTML to PDF option: a4 (default), letter
g_output_page_number_start_at varchar2(10 char) := null;  -- Change the start of the page numbers in the template
g_output_remove_last_page    boolean       := false; -- PDF option to remove the last page; e.g. when the last page is empty
g_output_remove_comments     boolean       := false; -- Option to remove comments from the output document, works for Word, Excel, Powerpoint, PDF 
g_output_batch_selector      varchar2(500 char) := null;  -- The hierarchy of data selector to point the data key that needs to be batch/split, e.g: orders:products 
g_output_batch_size          number        := null;   -- Number of batches to generate; refers to number of files to split into
g_output_batch_condition     varchar2(500 char)  := null;  -- Batch condition to generate batch E.g-1: category , E.g-2: unit_price > 100? "Expensive" : unit_price < 50 ? "Cheap" : "Medium"
g_output_ignore_conv_errors  boolean       := false; -- PDF option to ignore conversion errors during appending and prepending of files
g_output_modified_date       varchar2(50 char)  := null;  -- Word/Powerpoint template option to set the modified date of the file. Must be in ISO format (Example: "2022-02-07T12:55:12") or in the date time format ("YYYY-MM-DD HH:mm:ss", "YYYY-MM-DD")
g_output_created_date        varchar2(50 char)  := null;  -- Word/Powerpoint template option to set the created date of the file. Must be in ISO format (Example: "2022-02-07T12:55:12") or in the date time format ("YYYY-MM-DD HH:mm:ss", "YYYY-MM-DD")
g_output_compression         varchar2(10 char)  := null;  -- Compression algorithm: zip
g_output_compression_name    varchar2(50 char)  := null;  -- Name of the file after compression
g_output_form_fill_font      varchar2(250 char) := null;  -- The name of the font when filling in a PDF Form, The font must be installed on the system, or provided as a file on assets folder or root of aop.
g_output_attachment_text     varchar2(250 char) := null;  -- Specify the information string you want to place in the attachment retrieved from eml file (email), e.g. "Current Page: {attachmentCurrentPage} Total Pages: {attachmentTotalPage} Attachment Number : {attachmentIndex} of {attachmentFilename}"
g_output_attachment_text_pos varchar2(20 char)  := null;  -- The position of attachment text in the attachment retrieved from eml file (email), e.g. bottom-left, bottom-right, top-left, top-right or center
g_output_attachment_xml_json boolean       := false;  -- While retrieving PDF attachments, if the attachment is an xml file, convert it to json.  
g_output_insert_barcode      boolean       := false; -- Insert a barcode in the PDF. This option should be provided as true while using {|barcode} tag on pdf template      


--### Async call to AOP; a URL will be returned where the file can be polled from 
g_async_status               varchar2(4000 char):= null;  -- Get the status of the async call (OK, error, false)
g_async_message              varchar2(4000 char):= null;  -- Get the status message of the async call 
g_async_url                  varchar2(4000 char):= null;  -- Get the URL where you can get the file when processing is complete

--### Call a Web Service where AOP will send the file to (POST Request)
g_web_service_url            varchar2(500 char) := null;  -- URL to be called once AOP has created the document. AOP will do a POST request and headers can be specified
g_web_service_headers        varchar2(4000 char):= null;  -- The headers for the POST request e.g. {"file_id": "F123", "access_token": "A456789"}

--### Files
g_prepend_files_sql          clob          := null;  -- format: select filename, mime_type, [file_blob, file_base64, url_call_from_db, url_call_from_aop, file_on_aop_server], [read_password] from my_table
g_append_files_sql           clob          := null;  -- format: select filename, mime_type, [file_blob, file_base64, url_call_from_db, url_call_from_aop, file_on_aop_server], [read_password] from my_table
g_compare_files_sql          clob          := null;  -- format: select filename, mime_type, [file_blob, file_base64, url_call_from_db, url_call_from_aop, file_on_aop_server], [read_password] from my_table
g_media_files_sql            clob          := null;  --  
g_output_prepend_per_page    boolean       := false; -- Prepend one or more pages before each page in the output. E.g. logo and company details before every document
g_output_append_per_page     boolean       := false; -- Append one or more pages after each page in the output. E.g. terms of conditions after every invoice

--### Templates
g_template_start_delimiter   varchar2(2 char)   := null;  -- { is the default start delimiter used is a template, but you can set this variable with the following options: {, {{, <, <<
g_template_end_delimiter     varchar2(2 char)   := null;  -- } is the default end delimiter used in a template, but you can set this variable with the following options: }, }}, >, >>
g_cache_template             boolean       := false; -- cache the template; an hash is returned in g_template_cache_hash
g_template_cache_hash        varchar2(128 char) := null;  -- the hashed value of the cached version of the template on the AOP Server/Cloud
g_use_template_when_no_cache varchar2(1 char)   := c_n;   -- by default when a template hash is sent and it's no longer available it will raise an error.
                                                     -- when set to Y(es), AOP will first check if the template is still available and if not include the full template when available.

--### Sub-Templates
g_sub_templates_sql          clob          := null;  -- format: select filename, mime_type, [file_blob, file_base64, url_call_from_db, url_call_from_aop, file_on_aop_server, name] from my_table

--### Attachments
g_attachments_sql       clob          := null;  -- format: select filename, mime_type, [file_blob, file_base64, url_call_from_db, url_call_from_aop, file_on_aop_server, name] from my_table

--### Password protected PDF
g_output_read_password       varchar2(200 char) := null; -- protect PDF to read / provide the password for Office Documents
g_output_modify_password     varchar2(200 char) := null; -- protect PDF to write (modify)
g_output_pwd_protection_flag number(4)     := null; -- optional; default is 4. 
                                                    -- Number when bit calculation is done as specified in http://pdfhummus.com/post/147451287581/hummus-1058-and-pdf-writer-updates-encryption
g_output_pdf_producer        varchar2(4000):= null; -- PDF meta-data set producer data tag
g_output_watermark           varchar2(4000):= null; -- Watermark in PDF
g_output_watermark_color     varchar2(500) := null; -- Watermark option color
g_output_watermark_font      varchar2(500) := null; -- Watermark option font
g_output_watermark_size      varchar2(500) := null; -- Watermark option width
g_output_watermark_opacity   varchar2(500) := null; -- Watermark option opacity
g_output_watermark_rotation  varchar2(500) := null; -- Watermark option rotation
g_output_copies              number        := null; -- Requires output pdf, repeats the output pdf for the given number of times.

--### IG
g_ig_force_query             varchar2(1 char)   := null; -- force the IG to use AOPs own implementation instead of apex_region.open_query_context
g_ig_use_alternative_label   varchar2(1 char)   := null; -- force the IG to use the alternative label for the heading

--### JSON
g_anonymize_json             varchar2(1 char)   := c_n;   -- set to Y (c_y) if you want to anomyze/obfuscate the JSON that is send over. This is great for debugging of sensitive data.
g_use_data_export_pjson      varchar2(1 char)   := c_n;   -- instead of using the AOP specific code to generate the meta-data of reports, use apex_data_export.c_format_pjson

--### CSV
g_output_text_delimiter      varchar2(200 char) := null;  -- delimiter for tags
g_output_field_separator     varchar2(200 char) := null;  -- field separator, default is ,
g_output_character_set       varchar2(200 char) := null;  -- character set of CSV file 

--### Word
g_update_toc                 boolean       := false; -- Update the table of contents in Word document

--### DATA EXPORT - APEX 20.2 and higher
$if wwv_flow_api.c_current >= 20201001
$then 
g_data_export_component_id   number                         := null;
g_data_export_view_mode      varchar2(100 char)             := null;
g_data_export_max_rows       number                         := null;
g_data_export_file_name      varchar2(255 char)             := null;
g_data_export_page_size      apex_data_export.t_size        := apex_data_export.c_size_letter;
g_data_export_orientation    apex_data_export.t_orientation := apex_data_export.c_orientation_portrait;
g_data_export_data_only      boolean                        := false;
g_data_export_pdf_accessible boolean                        := false;  
$end  

--### OCI
g_oci_credential             varchar2(150 char) := null;  -- Credentials used in sys.DBMS_CLOUD (Oracle Cloud Infrastructure credentials)
g_oci_directory_name         varchar2(150 char) := null;  -- Directory name used in sys.DBMS_CLOUD 

--### Inline Region
g_inline_region_static_id    varchar2(150 char) := null;  -- Used when Output To is set to Inline Region

--### APEX Office Edit (AOE)
g_aoe_region_static_id       varchar2(150 char) := null;  -- Used when Output To is set to c_apex_office_edit 
                                                     -- Specify here the Static ID of the APEX Office Edit Plug-in region 
g_aoe_primary_key_items      varchar2(4000 char) := null; -- the primary key items defined in APEX Office Edit colon separated (will be automatically filled)
g_aoe_primary_key_values     varchar2(4000 char) := null; -- the primary key values of the records that where created by the procedure colon separated

--### PDF Region Pro
g_pdf_region_static_id       varchar2(150 char) := null;  -- Used when Output To is set to c_pdf_region_pro
                                                     -- Specify here the Static ID of the PDF Region Pro Plug-in region 
g_pdf_primary_key_items      varchar2(4000 char) := null; -- the primary key items defined in PDF Region Pro colon separated (will be automatically filled)
g_pdf_primary_key_values     varchar2(4000 char) := null; -- the primary key values of the records that where created by the procedure colon separated


--## EXCEPTIONS
/**
 * @exception 
 */


--### FUNCTIONS AND PROCEDURES   
-- ! package body contains documentation

-- debug function, will write to apex_debug_messages, logger (if enabled) and your own debug procedure
procedure aop_debug(p_message     in varchar2, 
                    p0            in varchar2 default null, 
                    p1            in varchar2 default null, 
                    p2            in varchar2 default null, 
                    p3            in varchar2 default null, 
                    p4            in varchar2 default null, 
                    p5            in varchar2 default null, 
                    p6            in varchar2 default null, 
                    p7            in varchar2 default null, 
                    p8            in varchar2 default null, 
                    p9            in varchar2 default null, 
                    p10           in varchar2 default null, 
                    p11           in varchar2 default null, 
                    p12           in varchar2 default null, 
                    p13           in varchar2 default null, 
                    p14           in varchar2 default null, 
                    p15           in varchar2 default null, 
                    p16           in varchar2 default null, 
                    p17           in varchar2 default null, 
                    p18           in varchar2 default null, 
                    p19           in varchar2 default null, 
                    p_level       in apex_debug.t_log_level default apex_debug.c_log_level_info, 
                    p_description in clob default null);


-- convert clob to base64, handy for HTML templates 
function clob2base64(p_clob in clob)
return clob;

-- convert base64 to clob
function base642clob(p_base64 in clob)
return clob;

-- convert a url with for example an image to base64
function url2base64 (
  p_url in varchar2)
  return clob;

-- get the value of one of the above constants
function getconstantvalue (
  p_constant in varchar2)
  return varchar2 deterministic;

-- get the mime type of a file extention: docx, xlsx, pptx, pdf
function getmimetype (
  p_file_ext in varchar2)
  return varchar2 deterministic;

-- get the file extention of a mime type
function getfileextension (
  p_mime_type in varchar2)
  return varchar2 deterministic;  

-- get the Font Awesome / APEX icon of a mime type
function geticon (
  p_mime_type in varchar2)
  return varchar2 deterministic;  

-- convert a blob to a clob
function blob2clob(p_blob in blob)
  return clob;

-- convert a clob to a blob
function clob2blob(p_clob in clob)
  return blob;

-- convert a blob to a file in the database directory
procedure blob2file(p_blob      in blob,
                    p_directory in varchar2,
                    p_filename  in varchar2);

-- convert a file to a blob
function file2blob(p_directory in varchar2,
                   p_filename  in varchar2)
  return blob;

-- internal function to check a server-side condition
function is_component_used_yn(p_build_option_id         in number default null,
                              p_authorization_scheme_id in varchar2,
                              p_condition_type          in varchar2,
                              p_condition_expression1   in varchar2,
                              p_condition_expression2   in varchar2,
                              p_component               in varchar2 default null,
                              p_report_column           in varchar2 default null)
  return varchar2;

-- internal function to get the bind variables of a SQL statement
function get_binds (
    p_stmt in clob )
    return sys.dbms_sql.varchar2_table;

-- check template and output type compatibility
-- template and output type can be mime_type or file extension
function is_valid_output_type(p_template_type in varchar2,
                              p_output_type   in varchar2)
  return boolean;

-- check if the hash of the template cache is still valid and present on the AOP Server/Cloud
function is_valid_template_hash(p_aop_url in varchar2 default g_aop_url,
                                p_hash    in varchar2)
  return boolean;


/**
 * @Description: Call to AOP Server through API, used behind the scenes by the APEX plug-in, but a manual call can be done with PL/SQL too.
 *
 * @Author: Dimitri Gielis
 * @Created: 2016-8-2
 *
 * @Param: p_data_type Define where the data is coming from. 
 *                     Following constants exists in aop_api_pkg: c_source_type_sql, c_source_type_plsql_sql, c_source_type_plsql, c_source_type_url, c_source_type_rpt, c_source_type_refcursor, c_source_type_sql_array, c_source_type_xml, c_source_type_json, c_source_type_json_files, c_source_type_none
 * @Param: p_data_source Depending the data type, define here the source:
 *                         - c_source_type_sql: SQL statement with cursor syntax or returning JSON
 *                         - c_source_type_plsql_sql: PL/SQL function returning SQL statement with mime type and blob
 *                         - c_source_type_plsql: PL/SQL function returning JSON with the template file base64 encoded
 *                         - c_source_type_url: URL which contains the file
 *                         - c_source_type_rpt: static id(s) or region id(s) of the APEX regions
 *                         - c_source_type_refcursor: REF Cursor
 *                         - c_source_type_sql_array: Array of SQL statements
 *                         - c_source_type_xml: XML
 *                         - c_source_type_json: JSON data part
 *                         - c_source_type_json_files: JSON including files
 *                         - c_source_type_none: leave the source blank
 * @Param: p_template_type Define where the template is stored. 
 *                         Following constants exists in aop_api_pkg: c_source_type_apex, c_source_type_workspace, c_source_type_sql, c_source_type_plsql_sql, c_source_type_plsql, 
 *                                                                    c_source_type_url, c_source_type_filename, c_source_type_url_aop, c_source_type_json, c_source_type_db_directory, c_source_type_oci_objs, 
 *                                                                    c_source_type_aop_report, c_source_type_apex_report, c_source_type_aop_template, c_source_type_clob_base64, c_source_type_none
 * @Param: p_template_source Depending the template_type, define here the filename, SQL statement, PL/SQL function or URL:
 *                         - c_source_type_apex: file uploaded in APEX Static Application Files
 *                         - c_source_type_workspace: file uploaded in APEX Workspace Files
 *                         - c_source_type_sql: SQL statement returning mime type and blob
 *                         - c_source_type_plsql_sql: PL/SQL function returning SQL statement with mime type and blob
 *                         - c_source_type_plsql: PL/SQL function returning JSON with the template file base64 encoded
 *                         - c_source_type_url: URL which contains the file (will be read from DB server)
 *                         - c_source_type_url_aop: URL which contains the file (will be read from AOP server)
 *                         - c_source_type_filename: file specified in a directory on the AOP Server
 *                         - c_source_type_db_directory: file specified in a directory on the Database Server, use DIRECTORY:filename
 *                         - c_source_type_json: JSON with the template file base64 encoded 
 *                         - c_source_type_clob_base64: BLOB in CLOB base64 encoded (user apex_web_service.blob2clobbase64) 
 *                         - c_source_type_aop_template: AOP will generate a starter template
 *                         - c_source_type_aop_report: AOP will use it's own template, used to generate one or more APEX regions
 *                         - c_source_type_apex_report: APEX will generate one region (native functionality)
 *                         - c_source_type_oci_objs: Oracle Cloud Infrastructure - Object Storage
 *                         - c_source_type_none: leave the source blank
 * @Param: p_output_type Extension (pdf, xlsx, ...) or mime type (application/pdf, application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, ...) of the output format. 
 *                       Following constants exists in aop_api_pkg:
 *                         - c_word_docx             
 *                         - c_excel_xlsx            
 *                         - c_powerpoint_pptx    
 *                         - c_opendocument_odt        
 *                         - c_opendocument_ods        
 *                         - c_opendocument_odp           
 *                         - c_pdf_pdf               
 *                         - c_html_html             
 *                         - c_markdown_md           
 *                         - c_text_txt              
 *                         - c_csv_csv         
 *                         - c_word_rtf              
 *                         - c_onepagepdf_pdf        
 *                         - c_count_tags
 *                         - c_get_attachments
 *                         - c_xfa_form_fields
 *                         - c_form_fields
 *                         - c_defined_by_apex_item                           
 * @Param: p_output_filename Filename of the result
 * @Param: p_output_type_item_name APEX Item holding the filename
 * @Param: p_output_to Where does the blob or file need to be sent to: 
 *                         - c_output_browser: the browser will open the file          
 *                         - c_output_inline: the output is defined for showing inline in a region
 *                         - c_output_directory: the file is stored on the AOP Server in this directory
 *                         - c_output_db_directory: the file is stored on the Database Server in this directory 
 *                         - c_output_cloud: a file is sent to the cloud (Dropbox, Amazon S3, Google Drive, Oracle Cloud) using the credentials defined in g_cloud_provider, g_cloud_location and g_cloud_access_token
 *                         - c_output_procedure: a blob will be passed to a procedure which is defined in p_procedure. 
 *                           The procedure definition needs to be: proc_name(p_output_blob in blob, p_output_filename in varchar2, p_output_mime_type in varchar2)
 *                         - c_output_procedure_browser: a blob will be passed to a procedure which is defined in p_procedure and the file is sent to the browser
 *                         - c_output_procedure_inline: a blob will be passed to a procedure which is defined in p_procedure and the file is showing inline in a region
 *                         - c_output_async: the blob will be empty and a URL will be passed to g_async_url where the file will be available to download when AOP is finished. Use the poll_async_file procedure to check and download the file.
 *                           Optionally a procedure can be defined in p_procedure with the following definition: proc_name(p_async_status in varchar2, p_async_message in varchar2, p_async_url in varchar2, p_output_filename in varchar2, p_output_mime_type in varchar2)
 *                         - c_output_web_service: AOP will call the web service (a POST Request) defined in g_web_service_url once AOP is finished producing the file. Extra headers can be added to the POST request by defining them in g_web_service_headers 
 *                         - c_apex_office_edit: a blob will be passed to a procedure which is defined in p_procedure and the file can be shown directly in APEX Office Edit (AOE), the editor that can show and edit Word, Excel, PowerPoint, PDF, and Text straight from the browser. 
 *                           The procedure definition needs to be: proc_name(p_output_blob in blob, p_output_filename in varchar2, p_output_mime_type in varchar2)
 * @Param: p_procedure Procedure that needs to be called when the file is merged
 * @Param: p_binds Bind variable for SQL or PL/SQL Source
 * @Param: p_special Special settings defined in the APEX Plug-in concerning Reports (colon separated).
 *                   Following constants can be used:
 *                        - c_special_number_as_string 
 *                        - c_special_report_as_label  
 *                        - c_special_ir_filters_top   
 *                        - c_special_ir_highlights_top
 *                        - c_special_ir_excel_header_f
 *                        - c_special_ir_saved_report  
 *                        - c_special_ir_repeat_header 
 * @Param: p_aop_remote_debug Turning debugging on will generate the JSON that is sent to the AOP Server in a file. The actual request to the AOP Server is not done. Following constants can be used:
 *                        - c_debug_remote: store the JSON in your dashboard on https://www.apexofficeprint.com
 *                        - c_debug_local: store the JSON local on your pc
 *                        - c_debug_application_item: depending the Application item AOP_DEBUG, Remote (Yes) or Local (Local) or no debugging is done
 * @Param: p_output_converter Define the PDF converter you want to use. Multiple converters can be defined in the AOP Server. e.g. officetopdf, libreoffice, libreoffice-standalone
 * @Param: p_aop_url Description: URL where the AOP Server is running. For the AOP Cloud use c_aop_url
 * @Param: p_api_key Description: API Key which can be found when you login at https://www.apexofficeprint.com
 * @Param: p_app_id APEX Application ID
 * @Param: p_page_id Page ID to call in the APEX application
 * @Param: p_user_name Username which should be used to create an APEX session
 * @Param: p_init_code Initialisation code which can be invoked in this package
 * @Param: p_output_encoding Following constants can be used: c_output_encoding_raw, c_output_encoding_base64
 * @Param: p_output_split Split PDF in multiple pages and create zip
 * @Param: p_output_split_by_page Split PDF in multiple number of pages specified and create a zip
 * @Param: p_output_split_by_string Split PDF in multiple pages by string present on the page and create a zip
 * @Param: p_output_merge Merge multiple files to one PDF
 * @Param: p_failover_aop_url: URL where the AOP Failover Server is running. For the AOP Cloud use c_aop_url_fallback
 * @Param: p_failover_procedure: Procedure which is called when the failover URL is being used, so you are warned the main AOP server has issues.
 * @Param: p_log_procedure: Procedure which can be defined to do your own extra logging.
 * @Param: p_prepend_files_sql: SQL statement which hold the files to include before the main report.
 *                              Format: select filename, mime_type, [file_blob, file_base64, url_call_from_db, url_call_from_aop, file_on_aop_server, read_password] from my_table
 *                              Between [] is optional and one or more columns can be included
 * @Param: p_append_files_sql: SQL statement which hold the files to include after the main report.
 *                             Format: select filename, mime_type, [file_blob, file_base64, url_call_from_db, url_call_from_aop, file_on_aop_server, read_password] from my_table
 *                             Between [] is optional and one or more columns can be included
 * @Param: p_compare_files_sql: SQL statement which hold the files to include after the main report.
 *                             Format: select filename, mime_type, [file_blob, file_base64, url_call_from_db, url_call_from_aop, file_on_aop_server, read_password] from my_table
 *                             Between [] is optional and one or more columns can be included
 * @Param: p_media_files_sql: Coming soon (!); use AME API via https://www.apexmediaextension.com
 *                              Format: select filename, mime_type, [file_blob, file_base64, url_call_from_db, url_call_from_aop, file_on_aop_server], 
 *                                             [media_width, media_max_width, media_height, media_max_height, media_watermark_text, media_watermark_image, media_properties, media_output_file_type]
 *                                        from my_table
 *                              Between [] is optional and one or more columns can be included
 * @Param: p_sub_templates_sql: SQL statement which hold the sub-template Word documents.
 *                             Format: select filename, mime_type, [file_blob, file_base64, url_call_from_db, url_call_from_aop, file_on_aop_server] from my_table
 *                             Between [] is optional and one or more columns can be included 
 * @Param: p_attachments_sql: SQL statement which hold the attachments for PDF file.
 *                             Format: select filename, mime_type, [file_blob, file_base64, url_call_from_db, url_call_from_aop, file_on_aop_server] from my_table
 *                             Between [] is optional and one or more columns can be included 
 * @Param: p_ref_cursor: when data type is c_source_type_refcursor, we will read the ref cursor specified here 
 * @Param: p_sql_array:  when data type is c_source_type_sql_arrea, different SQL statements can be passed by using t_query_list
 * @Param: p_ig_selected_pks: add a json object with the regions and selected primary keys in format {"region_static_id": pk} e.g. {"customers": 1}
 * @Return: blob in defined output format containing result of merged template(s) with data and prepend and append files.
 *
 * @Example:
 *<code> 
 *declare
 *  l_binds           wwv_flow_plugin_util.t_bind_list;
 *  l_return          blob;
 *  l_output_filename varchar2(300) := 'output';
 *begin
 *  -- set the output to JSON, so we see what is being sent to the AOP Server (uncomment next line)
 *  -- aop_api_pkg.g_debug := 'Local';
 *  -- set output to own custom debug table (uncomment next line)
 *  -- aop_api_pkg.g_debug_procedure := 'aop_sample_pkg.custom_debug';
 *  --
 *  -- most minimalistic example 
 *  l_return := aop_api_pkg.plsql_call_to_aop (
 *                p_data_type       => aop_api_pkg.c_source_type_json,
 *                p_data_source     => '[{"hello":"world"}]',
 *                p_template_type   => aop_api_pkg.c_source_type_aop_template,
 *                p_output_type     => 'docx',
 *                p_output_filename => l_output_filename,
 *                p_aop_url         => 'http://localhost:8010'); 
 *  --
 *  --
 *  l_return := aop_api_pkg.plsql_call_to_aop (
 *                p_data_type       => aop_api_pkg.c_source_type_rpt,
 *                p_data_source     => 'report1',
 *                p_template_type   => null,
 *                p_template_source => '',
 *                p_output_type     => 'docx',
 *                p_output_filename => l_output_filename,
 *                p_binds           => l_binds,
 *                p_aop_url         => 'http://api.apexofficeprint.com',
 *                p_api_key         => '<your API key>', -- change the API key if you use the AOP Cloud
 *                p_app_id          => 498,              -- change to APEX app id
 *                p_page_id         => 100);             -- change to APEX page id
 *  
 *  -- write output to table (uncomment next line)
 *  -- insert into aop_output (output_blob, filename) values (l_return, l_output_filename);              
 *end;
*/
function plsql_call_to_aop(
  p_data_type                 in varchar2 default c_source_type_sql,
  p_data_source               in clob     default null,
  p_template_type             in varchar2 default c_source_type_apex,
  p_template_source           in clob     default null,
  p_output_type               in varchar2 default c_pdf_pdf,
  p_output_filename           in out nocopy varchar2,
  p_output_type_item_name     in varchar2 default null,
  p_output_to                 in varchar2 default null,
  p_procedure                 in varchar2 default null,
  p_binds                     in wwv_flow_plugin_util.t_bind_list default c_binds,
  p_special                   in varchar2 default null,
  p_aop_remote_debug          in varchar2 default c_no,
  p_output_converter          in varchar2 default null,
  p_aop_url                   in varchar2 default null,
  p_api_key                   in varchar2 default null,
  p_aop_mode                  in varchar2 default null,
  p_app_id                    in number   default null,
  p_page_id                   in number   default null,
  p_user_name                 in varchar2 default null,
  p_init_code                 in clob     default c_init_null,
  p_output_encoding           in varchar2 default c_output_encoding_raw,
  p_output_split              in varchar2 default c_false,
  p_output_merge              in varchar2 default c_false,
  p_output_even_page          in varchar2 default c_false,
  p_output_merge_making_even  in varchar2 default c_false,
  p_failover_aop_url          in varchar2 default null,
  p_failover_procedure        in varchar2 default null,
  p_log_procedure             in varchar2 default null,
  p_prepend_files_sql         in clob     default null,
  p_append_files_sql          in clob     default null,
  p_compare_files_sql         in clob     default null,
  p_media_files_sql           in clob     default null,
  p_sub_templates_sql         in clob     default null,
  p_attachments_sql           in clob     default null,
  p_ref_cursor                in sys_refcursor default null,
  p_sql_array                 in t_query_list default c_sql_array,
  p_ig_selected_pks           in varchar2 default null)
  return blob;

-- retrieve underlaying PL/SQL code of APEX Plug-in call
function show_plsql_call_plugin(
  p_process_id            in number   default null,
  p_dynamic_action_id     in number   default null,
  p_show_api_key          in varchar2 default c_no)
  return clob;

-- check to see if the AOP Server is running (function returning boolean)
function is_aop_accessible(
  p_url             in varchar2,
  p_proxy_override  in varchar2 default null,
  p_wallet_path     in varchar2 default null,
  p_wallet_pwd      in varchar2 default null)
  return boolean;

-- check to see if the AOP Server is running (procedure returning with sys.htp.p and sys.dbms_output)
procedure is_aop_accessible(
  p_url             in varchar2,
  p_proxy_override  in varchar2 default null,
  p_wallet_path     in varchar2 default null,
  p_wallet_pwd      in varchar2 default null);

-- send a sample request to the AOP Server
procedure send_aop_sample(
  p_url             in varchar2,
  p_api_key         in varchar2 default null,
  p_proxy_override  in varchar2 default null,
  p_wallet_path     in varchar2 default null,
  p_wallet_pwd      in varchar2 default null);

-- check the version of the AOP Server (function)
function get_aop_server_version(
  p_url             in varchar2,
  p_proxy_override  in varchar2 default null,
  p_wallet_path     in varchar2 default null,
  p_wallet_pwd      in varchar2 default null)
  return varchar2;

-- check the version of the AOP Server (procedure)
procedure show_aop_server_version(
  p_url             in varchar2,
  p_proxy_override  in varchar2 default null,
  p_wallet_path     in varchar2 default null,
  p_wallet_pwd      in varchar2 default null);

-- check the version of the AOP Server (function)
function get_aop_plsql_version
  return varchar2;

-- check the version of the AOP Server (procedure)
procedure show_aop_plsql_version;

-- get supported template types (function)
function get_aop_template_types(
  p_url             in varchar2,
  p_proxy_override  in varchar2 default null,
  p_wallet_path     in varchar2 default null,
  p_wallet_pwd      in varchar2 default null)
  return varchar2;

-- get supported template types (procedure)
procedure show_aop_template_types(
  p_url             in varchar2,
  p_proxy_override  in varchar2 default null,
  p_wallet_path     in varchar2 default null,
  p_wallet_pwd      in varchar2 default null);

-- get supported output types (function)
function get_aop_output_type_for_tmpl(
  p_url             in varchar2,
  p_template_type   in varchar2 default null,
  p_proxy_override  in varchar2 default null,
  p_wallet_path     in varchar2 default null,
  p_wallet_pwd      in varchar2 default null)
  return varchar2;

-- get supported output types (function)
procedure show_aop_output_type_for_tmpl(
  p_url             in varchar2,
  p_template_type   in varchar2 default null,
  p_proxy_override  in varchar2 default null,
  p_wallet_path     in varchar2 default null,
  p_wallet_pwd      in varchar2 default null);

-- async call to retrieve the file based on a URL
procedure poll_async_file (
  p_aop_url              in varchar2,
  p_proxy_override       in varchar2 default null,
  p_wallet_path          in varchar2 default null,
  p_wallet_pwd           in varchar2 default null,
  p_async_url            in varchar2,
  o_async_status         out varchar2,
  o_async_message        out varchar2,
  o_async_file           out blob);


-- APEX Plugins

-- Process Type Plugin
function f_process_aop(
  p_process in apex_plugin.t_process,
  p_plugin  in apex_plugin.t_plugin)
  return apex_plugin.t_process_exec_result;

-- Dynamic Action Plugin
function f_render_aop (
  p_dynamic_action in apex_plugin.t_dynamic_action,
  p_plugin         in apex_plugin.t_plugin)
  return apex_plugin.t_dynamic_action_render_result;

function f_ajax_aop(
  p_dynamic_action in apex_plugin.t_dynamic_action,
  p_plugin         in apex_plugin.t_plugin)
  return apex_plugin.t_dynamic_action_ajax_result;


-- Other Procedure

-- Create an APEX session from PL/SQL
-- p_enable_debug: Yes / No (default)
procedure create_apex_session(
  p_app_id       in apex_applications.application_id%type,
  p_user_name    in apex_workspace_sessions.user_name%type default 'ADMIN',
  p_page_id      in apex_application_pages.page_id%type default null,
  p_session_id   in apex_workspace_sessions.apex_session_id%type default null,
  p_enable_debug in varchar2 default 'No');

-- Get the current APEX Session
function get_apex_session
  return apex_workspace_sessions.apex_session_id%type;

-- Join an APEX Session
procedure join_apex_session(
  p_session_id   in apex_workspace_sessions.apex_session_id%type,
  p_app_id       in apex_applications.application_id%type default null,
  p_page_id      in apex_application_pages.page_id%type default null,
  p_enable_debug in varchar2 default 'No');

-- Drop the current APEX Session
procedure drop_apex_session(
  p_app_id     in apex_applications.application_id%type default null,
  p_session_id in apex_workspace_sessions.apex_session_id%type default null);

end aop_api25_pkg;
/
create or replace package aop_plsql25_pkg
AUTHID CURRENT_USER
as

/* Copyright 2015-2025 - APEX RnD - United Codes
*/

/* AOP Version */
c_aop_version  constant varchar2(6)   := '25.1.2';

--
-- Pre-requisites: apex_web_service package
-- if APEX is not installed, you can use this package as your starting point
-- but you would need to change the apex_web_service calls by utl_http calls or similar
--


--
-- Change following variables for your environment
--
g_aop_url  varchar2(200) := 'http://api.apexofficeprint.com/';                  -- for https use https://api.apexofficeprint.com/
g_api_key  varchar2(200) := '';    -- change to your API key in APEX 18 or above you can use apex_app_setting.get_value('AOP_API_KEY')
g_aop_mode varchar2(15)  := null;  -- AOP Mode can be development or production; when running in development no cloud credits are used but a watermark is printed                                                    

-- Global variables
-- Call to AOP
g_proxy_override          varchar2(300) := null;  -- null=proxy defined in the application attributes
g_transfer_timeout        number(6)     := 180;   -- default is 180
g_wallet_path             varchar2(300) := null;  -- null=defined in Manage Instance > Instance Settings
g_wallet_pwd              varchar2(300) := null;  -- null=defined in Manage Instance > Instance Settings

-- Output parameters
--### Output
g_output_directory          varchar2(200) := '.';   -- set output directory on AOP Server, if . is specified the files are saved in the default directory: outputfiles
g_output_sign_certificate   varchar2(32000) := null;-- sign PDF with signature which is base64 encoded
g_output_split              varchar2(5)   := null;  -- split file: one file per page: true/false
g_output_merge              varchar2(5)   := null;  -- merge files into one PDF true/false
g_output_icon_font          varchar2(20)  := null;  -- the icon font to use for the output, Font-APEX or Font Awesome 5 (default)
g_output_even_page          varchar2(5)   := null;  -- PDF option to always print even pages (necessary for two-sided pages): true/false
g_output_merge_making_even  varchar2(5)   := null;  -- PDF option to merge making all documents even paged (necessary for two-sided pages): true/false
g_output_page_margin        varchar2(50)  := null;  -- HTML to PDF option: margin in px, can also add top, bottom, left, right
g_output_page_orientation   varchar2(10)  := null;  -- HTML to PDF option: portrait (default) or landscape
g_output_page_width         varchar2(10)  := null;  -- HTML to PDF option: width in px, mm, cm, in. No unit means px.
g_output_page_height        varchar2(10)  := null;  -- HTML to PDF option: height in px, mm, cm, in. No unit means px.
g_output_page_format        varchar2(10)  := null;  -- HTML to PDF option: a4 (default), letter
g_output_remove_last_page   boolean       := false; -- PDF option to remove the last page; e.g. when the last page is empty
--### PDF
g_output_read_password      varchar2(200) := null;  -- protect PDF to read
g_output_modify_password    varchar2(200) := null;  -- protect PDF to write (modify)
g_output_pwd_protection_flag number(4)    := null;  -- optional; default is 4. 
                                                    -- Number when bit calculation is done as specified in http://pdfhummus.com/post/147451287581/hummus-1058-and-pdf-writer-updates-encryption
g_output_correct_page_nr    boolean        := false;-- boolean to check for AOPMergePage text to replace it with the page number.
g_output_lock_form          boolean        := false;-- boolean that determines if the pdf forms should be locked/flattened.
g_identify_form_fields      boolean        := false;-- boolean that fills in the name of the fields of a PDF Form in the field itself so it's easy to identify which field is at what position
g_output_watermark          varchar2(4000) := null; -- Watermark in PDF
g_output_watermark_color    varchar2(500)  := null; -- Watermark option color
g_output_watermark_font     varchar2(500)  := null; -- Watermark option font
g_output_watermark_width    varchar2(500)  := null; -- Watermark option width
g_output_watermark_height   varchar2(500)  := null; -- Watermark option height
g_output_watermark_opacity  varchar2(500)  := null; -- Watermark option opacity
g_output_watermark_rotation varchar2(500)  := null; -- Watermark option rotation
g_output_copies             number         := null; -- Requires output pdf, repeats the output pdf for the given number of times.
g_output_insert_barcode     boolean        := false; -- boolean to insert barcode in PDF, default is false

--### CSV
g_output_text_delimiter     varchar2(200) := null;  -- 
g_output_field_separator    varchar2(200) := null;  -- 
g_output_character_set      varchar2(200) := null;  -- 

-- Constants
c_mime_type_docx        constant varchar2(100) := 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
c_mime_type_xlsx        constant varchar2(100) := 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
c_mime_type_pptx        constant varchar2(100) := 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
c_mime_type_pdf         constant varchar2(100) := 'application/pdf';
c_mime_type_html        constant varchar2(9)   := 'text/html';
c_mime_type_markdown    constant varchar2(13)  := 'text/markdown';


function make_aop_request(
  p_aop_url            in varchar2 default g_aop_url,
  p_api_key            in varchar2 default g_api_key,
  p_aop_mode           in varchar2 default g_aop_mode,  
  p_json               in clob,
  p_template           in blob,
  p_template_type      in varchar2 default null,
  p_output_encoding    in varchar2 default 'raw', -- change to raw to have binary, change to base64 to have base64 encoded
  p_output_type        in varchar2 default null,
  p_output_filename    in varchar2 default 'output',
  p_aop_remote_debug   in varchar2 default 'No',
  p_output_converter   in varchar2 default '',
  p_prepend_files_json in clob default null,
  p_append_files_json  in clob default null,
  p_templates_json     in clob default null
  )
  return blob;

end aop_plsql25_pkg;
/
create or replace package aop_plsql_only_pkg
authid current_user
as

/* Copyright 2015-2025 - APEX RnD - United Codes
*/

/* AOP Version */
c_aop_version  constant varchar2(6)   := '25.1.2';

--
-- PL/SQL only version, not needing Oracle APEX. Requests are being done by UTL_HTTP
--

--
-- Change following variables for your environment
--
g_aop_url  varchar2(200) := 'https://api.apexofficeprint.com/'; -- for http use http://api.apexofficeprint.com/
g_api_key  varchar2(200) := '';    -- change to your API key 
g_aop_mode varchar2(15)  := null;  -- AOP Mode can be development or production; when running in development no cloud credits are used but a watermark is printed                                                    

g_wallet_path varchar2(300 char) := null; -- specify for an HTTPS call
g_wallet_pwd  varchar2(300 char) := null; -- specify for an HTTPS call

g_output_converter varchar2(250) := null; 


-- Constants
c_mime_type_docx        constant varchar2(100) := 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
c_mime_type_xlsx        constant varchar2(100) := 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
c_mime_type_pptx        constant varchar2(100) := 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
c_mime_type_pdf         constant varchar2(100) := 'application/pdf';
c_mime_type_html        constant varchar2(9)   := 'text/html';
c_mime_type_markdown    constant varchar2(13)  := 'text/markdown';


-- Helper functions
function replace_with_clob(
   p_source in clob
  ,p_search in varchar2
  ,p_replace in clob
) return clob;

function blob2clobbase64(p_blob in blob)
return clob;


/**
 * @Description: Make a call to the AOP Server and generate the correct JSON with PL/SQL.               
 *
 * @Author: Dimitri Gielis
 * @Created: 29/7/2023
 *
 * @Param: p_aop_url  URL of AOP Server
 * @Param: p_api_key  API Key in case AOP Cloud is used
 * @Param: p_aop_mode  API Key in case AOP Cloud is used
 * @Param: p_data_json  Data in JSON format
 * @Param: p_template  Template in blob format
 * @Param: p_template_type  The type of the template e.g. docx, xlsx, pptx, html, txt, md
 * @Param: p_output_type  The extension of the output e.g. pdf, if no output type is defined, the same extension as the template is used
 * @Param: p_output_filename  Filename of the result
 * @Param: p_aop_debug  Ability to do local (or remote debugging in case the AOP Cloud is used)
 * @Param: p_prepend_files_json Prepend files
 * @Param: p_append_files_json Append Files
 * @Param: p_templates_json Use Sub-templates
 * @Param: p_output_json Configure extra output parameters e.g. output_page_height, output_page_format, output_page_number_start_at, output_remove_last_page
 * @Return: Resulting file where the template and data are merged and outputted in the requested format (output type).
 * @Example: 

-- Generate an AOP Template in Word based on the data I provide
declare
  l_blob blob;
begin
  l_blob := aop_plsql_only_pkg.make_aop_request(
              p_aop_url   => 'https://api.apexofficeprint.com/',
              p_api_key   => '',
              p_data_json => q'!
                                [
                                  {
                                    "filename": "file1",
                                    "data": [
                                        {
                                          "cust_city": "St. Louis",
                                          "cust_first_name": "Albertos",
                                          "cust_last_name": "Lambert",
                                          "orders": [
                                              {
                                                "order_name": "Order 1",
                                                "order_total": 950,
                                                "product": [
                                                    {
                                                        "product_name": "Business \nShirt",
                                                        "quantity": 3,
                                                        "unit_price": 50
                                                    },
                                                    {
                                                        "product_name": "Trousers",
                                                        "quantity": 2,
                                                        "unit_price": 80
                                                    }
                                                ]
                                              }
                                          ]
                                        }
                                    ]
                                  }
                                ]              
              !',
              p_output_type => 'docx'
            );

  insert into aop_output (output_blob, filename, mime_type, last_update_date)
  values (l_blob, 'plsql_only_doc.docx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', sysdate);          
end;  

-- Generate PDF based on Word template
declare
  l_template blob;
  l_pdf      blob;
begin
  select template_blob
    into l_template
    from aop_template
   where id = 1;

  l_pdf := aop_plsql_only_pkg.make_aop_request(
              p_aop_url   => 'https://api.apexofficeprint.com/',
              p_api_key   => '',
              p_template_type => 'docx',
              p_template  => l_template,
              p_data_json => q'!
                                [
                                  {
                                    "filename": "file1",
                                    "data": [
                                        {
                                          "cust_city": "St. Louis",
                                          "cust_first_name": "Albertos",
                                          "cust_last_name": "Lambert"
                                        }
                                    ]
                                  }
                                ]              
              !',
              p_output_type => 'pdf'
            );

  insert into aop_output (output_blob, filename, mime_type, last_update_date)
  values (l_pdf, 'plsql_only_pdf.pdf', 'application/pdf', sysdate);          
end;  
 *
 */
function make_aop_request(
  p_aop_url            in varchar2 default g_aop_url,
  p_api_key            in varchar2 default g_api_key,
  p_aop_mode           in varchar2 default g_aop_mode,  
  p_data_json          in clob,
  p_template           in blob default null,
  p_template_type      in varchar2 default null,
  p_output_type        in varchar2 default null,
  p_output_filename    in varchar2 default 'output',
  p_aop_debug          in varchar2 default 'No',
  p_prepend_files_json in clob default null,
  p_append_files_json  in clob default null,
  p_templates_json     in clob default null,
  p_output_json        in clob default null)
  return blob;

end aop_plsql_only_pkg;
/
create or replace package aop_convert25_pkg
AUTHID CURRENT_USER
as

/* Copyright 2015-2025 - APEX RnD - United Codes
*/

-- CONSTANTS

/* AOP Version */
c_aop_version             constant varchar2(6) := '25.1.2';
c_aop_url                 constant varchar2(50) := 'http://api.apexofficeprint.com/'; -- for https use https://api.apexofficeprint.com/
-- Mime Types
c_mime_type_docx          constant varchar2(100) := 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
c_mime_type_xlsx          constant varchar2(100) := 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
c_mime_type_pptx          constant varchar2(100) := 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
c_mime_type_pdf           constant varchar2(100) := 'application/pdf';
c_mime_type_html          constant varchar2(100) := 'text/html';
c_mime_type_markdown      constant varchar2(100) := 'text/markdown';
c_mime_type_rtf           constant varchar2(100) := 'application/rtf';
c_mime_type_json          constant varchar2(100) := 'application/json';
c_mime_type_text          constant varchar2(100) := 'text/plain';
c_mime_type_zip           constant varchar2(100) := 'application/zip';
c_pdf_pdf                 constant varchar2(3)  := 'pdf'; 
-- Output
c_output_encoding_raw     constant varchar2(3) := 'raw';
c_output_encoding_base64  constant varchar2(6) := 'base64';
/* Init */
c_init_null               constant varchar2(5) := 'null;';
c_source_type_sql         constant varchar2(3) := 'SQL';

-- VARIABLES

-- Logger
g_logger_enabled          boolean := false;       -- set to true to write extra debug output to logger - see https://github.com/OraOpenSource/Logger

-- Call to AOP
g_proxy_override          varchar2(300) := null;  -- null=proxy defined in the application attributes
g_https_host              varchar2(300) := null;  -- parameter for utl_http and apex_web_service
g_transfer_timeout        number(6)     := 1800;  -- default of APEX is 180
g_wallet_path             varchar2(300) := null;  -- null=defined in Manage Instance > Instance Settings
g_wallet_pwd              varchar2(300) := null;  -- null=defined in Manage Instance > Instance Settings
g_output_filename         varchar2(100) := null;  -- output
g_language                varchar2(2)   := 'en';  -- Language can be: en, fr, nl, de
g_logging                 clob          := '';    -- ability to add your own logging: e.g. "request_id":"123", "request_app":"APEX", "request_user":"RND"
g_debug                   varchar2(10)  := null;  -- set to 'Local' when only the JSON needs to be generated, 'Remote' for remore debug
g_debug_procedure         varchar2(4000):= null;  -- when debug in APEX is turned on, next to the normal APEX debug, this procedure will be called
   

--
-- Convert one or more files by using a SQL query with following syntax (between [] can be one or more columns)
-- select filename, mime_type, [file_blob, file_base64, url_call_from_db, url_call_from_aop, file_on_aop_server] from my_table
--
function convert_files(
  p_query                 in clob,
  p_output_type           in varchar2 default c_pdf_pdf,
  p_output_encoding       in varchar2 default c_output_encoding_raw,
  p_output_to             in varchar2 default null,
  p_output_filename       in out nocopy varchar2,  
  p_output_converter      in varchar2 default null,
  p_output_collection     in varchar2 default null,
  p_aop_remote_debug      in varchar2 default 'No',
  p_aop_url               in varchar2 default null,
  p_api_key               in varchar2 default null,
  p_aop_mode              in varchar2 default null,
  p_app_id                in number   default null,
  p_page_id               in number   default null,
  p_user_name             in varchar2 default null,
  p_init_code             in clob     default c_init_null,
  p_failover_aop_url      in varchar2 default null,
  p_failover_procedure    in varchar2 default null,
  p_log_procedure         in varchar2 default null,
  p_procedure             in varchar2 default null
) return blob;

--
-- Convert a blob from one format to the other
--
function convert_blob(
  p_blob                  in blob,
  p_mime_type             in varchar2 default null,
  p_output_type           in varchar2 default c_pdf_pdf,
  p_output_filename       in out nocopy varchar2,  
  p_aop_url               in varchar2 default null,
  p_api_key               in varchar2 default null,
  p_aop_mode              in varchar2 default null,
  p_failover_aop_url      in varchar2 default null,
  p_failover_procedure    in varchar2 default null,
  p_log_procedure         in varchar2 default null
) return blob;

-- APEX Plugins

-- Process Type Plugin
/*
function f_process_aop(
  p_process in apex_plugin.t_process,
  p_plugin  in apex_plugin.t_plugin)
  return apex_plugin.t_process_exec_result;
*/
-- Dynamic Action Plugin
function f_render_aop (
  p_dynamic_action in apex_plugin.t_dynamic_action,
  p_plugin         in apex_plugin.t_plugin)
  return apex_plugin.t_dynamic_action_render_result;

function f_ajax_aop(
  p_dynamic_action in apex_plugin.t_dynamic_action,
  p_plugin         in apex_plugin.t_plugin)
  return apex_plugin.t_dynamic_action_ajax_result;


end aop_convert25_pkg;
/
create or replace synonym aop_api_pkg for aop_api25_pkg;
create or replace synonym aop_plsql_pkg for aop_plsql25_pkg;
create or replace synonym aop_convert_pkg for aop_convert25_pkg;
create or replace package body aop_api25_pkg wrapped 
a000000
1
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
b
77aba 165d2
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

/
create or replace package body aop_plsql25_pkg as

/**
 * @Description: Package to show how to make a manual call with PL/SQL to the AOP Server
 *               If APEX is not installed, you can use this package as your starting point but you would need to change the apex_web_service calls by utl_http calls or similar.
 *
 * @Author: Dimitri Gielis
 * @Created: 12/12/2015
 */

function replace_with_clob(
   p_source in clob
  ,p_search in varchar2
  ,p_replace in clob
) return clob
as
  l_pos pls_integer;
begin
  l_pos := instr(p_source, p_search);
  if l_pos > 0 then
    return substr(p_source, 1, l_pos-1)
      || p_replace
      || substr(p_source, l_pos+length(p_search));
  end if;
  return p_source;
end replace_with_clob;


/**
 * @Description: Example how to make a manual call to the AOP Server and generate the correct JSON.               
 *
 * @Author: Dimitri Gielis
 * @Created: 9/1/2018
 *
 * @Param: p_aop_url URL of AOP Server
 * @Param: p_api_key API Key in case AOP Cloud is used
 * @Param: p_json Data in JSON format
 * @Param: p_template Template in blob format
 * @Param: p_template_type The type of the template e.g. docx, xlsx, pptx, html, txt, md
 * @Param: p_output_encoding Encoding in raw or base64
 * @Param: p_output_type The extension of the output e.g. pdf, if no output type is defined, the same extension as the template is used
 * @Param: p_output_filename Filename of the result
 * @Param: p_aop_remote_debug Ability to do remote debugging in case the AOP Cloud is used
 * @Param: p_output_converter 
 * @Param: p_prepend_files_json
 * @Param: p_append_files_json
 * @Param: p_templates_json
 * @Param: p_render_pdf_barcode Boolean to render a barcode in the PDF
 * @Return: Resulting file where the template and data are merged and outputted in the requested format (output type).
 */
function make_aop_request(
  p_aop_url            in varchar2 default g_aop_url,
  p_api_key            in varchar2 default g_api_key,
  p_aop_mode           in varchar2 default g_aop_mode,
  p_json               in clob,
  p_template           in blob,
  p_template_type      in varchar2 default null,
  p_output_encoding    in varchar2 default 'raw',  
  p_output_type        in varchar2 default null,
  p_output_filename    in varchar2 default 'output',
  p_aop_remote_debug   in varchar2 default 'No',
  p_output_converter   in varchar2 default '',
  p_prepend_files_json in clob default null,
  p_append_files_json  in clob default null,
  p_templates_json     in clob default null)
  return blob
as
  l_aop_json          clob;
  l_template_clob     clob;
  l_template_type     varchar2(10);
  l_data_json         clob;
  l_output_type       varchar2(10);
  l_blob              blob;
  l_error_description varchar2(32767);
  l_amount                   integer := dbms_lob.lobmaxsize;
  l_dest_offset              integer := 1 ;
  l_src_offset               integer := 1 ;
  l_blob_csid                integer := dbms_lob.default_csid;
  l_lang_context             integer := dbms_lob.default_lang_ctx;
  l_warning                  integer := dbms_lob.warn_inconvertible_char;
begin
  l_template_clob := apex_web_service.blob2clobbase64(p_template);
  l_template_clob := replace(l_template_clob, chr(13) || chr(10), null);
  l_template_clob := replace(l_template_clob, '"', '\u0022');

  if p_template_type is null 
  then
    if dbms_lob.instr(p_template, utl_raw.cast_to_raw('ppt/presentation'))> 0
    then
      l_template_type := 'pptx';
    elsif dbms_lob.instr(p_template, utl_raw.cast_to_raw('worksheets/'))> 0
    then
      l_template_type := 'xlsx';
    elsif dbms_lob.instr(p_template, utl_raw.cast_to_raw('word/document'))> 0
    then
      l_template_type := 'docx';
    elsif dbms_lob.instr(p_template, utl_raw.cast_to_raw('html'))> 0
    then
      l_template_type := 'html';
    else
      l_template_type := 'unknown';
    end if;
  else
      l_template_type := p_template_type;
  end if;

  if p_output_type is null
  then
    l_output_type := l_template_type;
  else
    l_output_type := p_output_type;
  end if;

  l_data_json := p_json;

  l_aop_json := '
  {
      "version": "***AOP_VERSION***",
      "api_key": "***AOP_API_KEY***",
      "mode": "***AOP_MODE***",
      "aop_remote_debug": "***AOP_REMOTE_DEBUG***",
      "template": {
        "file":"***AOP_TEMPLATE_BASE64***",
         "template_type": "***AOP_TEMPLATE_TYPE***"
      },
      "templates": 
        ***AOP_TEMPLATES_JSON***,
      "output": {
        "output_encoding": "***AOP_OUTPUT_ENCODING***",
        "output_type": "***AOP_OUTPUT_TYPE***",
        "output_converter": "***AOP_OUTPUT_CONVERTER***",
        "icon_font": "g_output_icon_font",
        "output_watermark": "g_output_watermark",
        "output_watermark_color": "g_output_watermark_color",
        "output_watermark_font": "g_output_watermark_font",
        "output_watermark_width": "g_output_watermark_width",
        "output_watermark_height": "g_output_watermark_height",
        "output_watermark_opacity": "g_output_watermark_opacity",
        "output_watermark_rotation": "g_output_watermark_rotation",
        "output_modify_password": "g_output_modify_password",  
        "output_read_password": "g_output_read_password",  
        "output_password_protection_flag": "g_output_pwd_protection_flag",  
        "output_correct_page_number": g_output_correct_page_nr,  
        "lock_form": g_output_lock_form,
        "identify_form_fields": g_identify_form_fields,
        "output_even_page": "g_output_even_page",
        "output_merge_making_even": "g_output_merge_making_even",
        "output_split": "g_output_split",
        "output_merge": "g_output_merge",
        "output_sign_certificate": "g_output_sign_certificate",
        "output_copies": "g_output_copies",
        "output_page_margin": "g_output_page_margin",
        "output_page_orientation": "g_output_page_orientation",
        "output_page_width": "g_output_page_width",
        "output_page_height": "g_output_page_height",
        "output_page_format": "g_output_page_format",
        "output_text_delimiter": "g_output_text_delimiter",
        "output_field_separator": "g_output_field_separator",
        "output_character_set": "g_output_character_set",
        "output_remove_last_page": "g_output_remove_last_page",
        "output_insert_barcode": "g_output_insert_barcode"
      },
      "files":
        ***AOP_DATA_JSON***,
      "prepend_files":
        ***AOP_PREPEND_FILES_JSON***,
      "append_files":
        ***AOP_APPEND_FILES_JSON***  
  }';

  l_aop_json := replace(l_aop_json, '***AOP_VERSION***', c_aop_version);
  l_aop_json := replace(l_aop_json, '***AOP_API_KEY***', p_api_key);
  l_aop_json := replace(l_aop_json, '***AOP_MODE***', p_aop_mode);
  l_aop_json := replace(l_aop_json, '***AOP_REMOTE_DEBUG***', p_aop_remote_debug);
  l_aop_json := replace_with_clob(l_aop_json, '***AOP_TEMPLATE_BASE64***', l_template_clob);
  l_aop_json := replace_with_clob(l_aop_json, '***AOP_TEMPLATE_TYPE***', l_template_type);
  l_aop_json := replace(l_aop_json, '***AOP_OUTPUT_ENCODING***', p_output_encoding);
  l_aop_json := replace(l_aop_json, '***AOP_OUTPUT_TYPE***', l_output_type);
  l_aop_json := replace(l_aop_json, '***AOP_OUTPUT_CONVERTER***', p_output_converter);
  l_aop_json := replace_with_clob(l_aop_json, '***AOP_DATA_JSON***', l_data_json);
  l_aop_json := replace_with_clob(l_aop_json, '***AOP_PREPEND_FILES_JSON***', nvl(p_prepend_files_json,'[]'));
  l_aop_json := replace_with_clob(l_aop_json, '***AOP_APPEND_FILES_JSON***', nvl(p_append_files_json,'[]'));
  l_aop_json := replace_with_clob(l_aop_json, '***AOP_TEMPLATES_JSON***', nvl(p_templates_json,'[]'));
  l_aop_json := replace(l_aop_json, 'g_output_icon_font', g_output_icon_font);
  l_aop_json := replace(l_aop_json, 'g_output_watermark_color', g_output_watermark_color);
  l_aop_json := replace(l_aop_json, 'g_output_watermark_font', g_output_watermark_font);
  l_aop_json := replace(l_aop_json, 'g_output_watermark_width', g_output_watermark_width);
  l_aop_json := replace(l_aop_json, 'g_output_watermark_height', g_output_watermark_height);
  l_aop_json := replace(l_aop_json, 'g_output_watermark_opacity', g_output_watermark_opacity);
  l_aop_json := replace(l_aop_json, 'g_output_watermark_rotation', g_output_watermark_rotation);
  l_aop_json := replace(l_aop_json, 'g_output_watermark', g_output_watermark);
  l_aop_json := replace(l_aop_json, 'g_output_modify_password', g_output_modify_password);
  l_aop_json := replace(l_aop_json, 'g_output_read_password', g_output_read_password);
  l_aop_json := replace(l_aop_json, 'g_output_pwd_protection_flag', to_char(g_output_pwd_protection_flag));
  l_aop_json := replace(l_aop_json, 'g_output_correct_page_nr', case when g_output_correct_page_nr then 'true' else 'false' end);
  l_aop_json := replace(l_aop_json, 'g_output_lock_form', case when g_output_lock_form then 'true' else 'false' end);
  l_aop_json := replace(l_aop_json, 'g_identify_form_fields', case when g_identify_form_fields then 'true' else 'false' end);
  l_aop_json := replace(l_aop_json, 'g_output_even_page', g_output_even_page);
  l_aop_json := replace(l_aop_json, 'g_output_merge_making_even', g_output_merge_making_even);
  l_aop_json := replace(l_aop_json, 'g_output_split', g_output_split);
  l_aop_json := replace(l_aop_json, 'g_output_merge', g_output_merge);
  l_aop_json := replace(l_aop_json, 'g_output_sign_certificate', g_output_sign_certificate);
  l_aop_json := replace(l_aop_json, 'g_output_copies', to_char(g_output_copies));
  l_aop_json := replace(l_aop_json, 'g_output_page_margin', g_output_page_margin);
  l_aop_json := replace(l_aop_json, 'g_output_page_orientation', g_output_page_orientation);
  l_aop_json := replace(l_aop_json, 'g_output_page_width', g_output_page_width);
  l_aop_json := replace(l_aop_json, 'g_output_page_height', g_output_page_height);
  l_aop_json := replace(l_aop_json, 'g_output_page_format', g_output_page_format);
  l_aop_json := replace(l_aop_json, 'g_output_text_delimiter', g_output_text_delimiter);
  l_aop_json := replace(l_aop_json, 'g_output_field_separator', g_output_field_separator);
  l_aop_json := replace(l_aop_json, 'g_output_character_set', g_output_character_set);
  l_aop_json := replace(l_aop_json, '"g_output_insert_barcode"', case when g_output_insert_barcode then 'true' else 'false' end );
  l_aop_json := replace(l_aop_json, 'g_output_remove_last_page', case when g_output_remove_last_page then 'true' else 'false' end);
  l_aop_json := replace(l_aop_json, '\\n', '\n');

  --logger.log(p_text  => 'AOP JSON: ' || p_message, p_scope => 'AOP', p_extra => l_aop_json);

  if p_aop_remote_debug = 'Local'
  then 
    dbms_lob.createtemporary(l_blob, false);
    dbms_lob.converttoblob (
        dest_lob    => l_blob,
        src_clob    => l_aop_json,
        amount      => l_amount,
        dest_offset => l_dest_offset,
        src_offset  => l_src_offset,
        blob_csid   => l_blob_csid,
        lang_context=> l_lang_context,
        warning     => l_warning
    );
  else
    apex_web_service.g_request_headers.delete;
    apex_web_service.g_request_headers(1).name := 'Content-Type';
    apex_web_service.g_request_headers(1).value := 'application/json';

    begin
      l_blob := apex_web_service.make_rest_request_b(
        p_url              => p_aop_url,
        p_http_method      => 'POST',
        p_body             => l_aop_json,
        p_proxy_override   => g_proxy_override,
        p_transfer_timeout => g_transfer_timeout,
        p_wallet_path      => g_wallet_path,
        p_wallet_pwd       => g_wallet_pwd);
    exception
    when others
    then
      raise_application_error(-20001,'Issue calling AOP Service (REST call: ' || apex_web_service.g_status_code || '): ' || CHR(10) || SQLERRM);
    end;

    -- read header variable and create error message
    -- HTTP Status Codes:
    --  200 is normal
    --  500 error received
    --  503 Service Temporarily Unavailable, the AOP server is probably not running
    if apex_web_service.g_status_code = 200
    then
      l_error_description := null;
    elsif apex_web_service.g_status_code = 503
    then
      l_error_description := 'AOP Server not running.';
    elsif apex_web_service.g_status_code = 500
    then
      for l_loop in 1.. apex_web_service.g_headers.count loop
        if apex_web_service.g_headers(l_loop).name = 'error_description'
        then
          l_error_description := apex_web_service.g_headers(l_loop).value;
          -- errors returned by AOP server are base64 encoded
          l_error_description := utl_encode.text_decode(l_error_description, 'AL32UTF8', UTL_ENCODE.BASE64);
        end if;
      end loop;
    else
      l_error_description := 'Unknown error. Check AOP server logs.';
    end if;

    -- YOU CAN STORE THE L_BLOB TO A LOCAL DEBUG TABLE AS AOP SERVER RETURNS A DOCUMENT WITH MORE INFORMATION
    --

    -- check if succesfull
    if apex_web_service.g_status_code <> 200
    then
      raise_application_error(-20002,'Issue returned by AOP Service (REST call: ' || apex_web_service.g_status_code || '): ' || CHR(10) || l_error_description);
    end if;
  end if;

  -- return print
  return l_blob;

end make_aop_request;

end aop_plsql25_pkg;
/
create or replace package body aop_plsql_only_pkg as

/**
 * @Description: Package to show how to make a manual call with PL/SQL to the AOP Server
 *               If APEX is not installed, you can use this package as your starting point but you would need to change the apex_web_service calls by utl_http calls or similar.
 *
 * @Author: Dimitri Gielis
 * @Created: 12/12/2015
 */

function replace_with_clob(
   p_source in clob
  ,p_search in varchar2
  ,p_replace in clob
) return clob
as
  l_pos pls_integer;
begin
  l_pos := instr(p_source, p_search);
  if l_pos > 0 then
    return substr(p_source, 1, l_pos-1)
      || p_replace
      || substr(p_source, l_pos+length(p_search));
  end if;
  return p_source;
end replace_with_clob;


function blob2clobbase64(p_blob in blob)
return clob
as
  l_step   pls_integer := 12000;
  l_base64 clob;
begin
  for i in 0 .. trunc((dbms_lob.getlength(p_blob) - 1 )/l_step) loop
    l_base64 := l_base64 || sys.utl_raw.cast_to_varchar2(sys.utl_encode.base64_encode(dbms_lob.substr(p_blob, l_step, i * l_step + 1)));
  end loop;  

  return l_base64;
end blob2clobbase64;


--
function make_aop_request(
  p_aop_url            in varchar2 default g_aop_url,
  p_api_key            in varchar2 default g_api_key,
  p_aop_mode           in varchar2 default g_aop_mode,  
  p_data_json          in clob,
  p_template           in blob default null,
  p_template_type      in varchar2 default null,
  p_output_type        in varchar2 default null,
  p_output_filename    in varchar2 default 'output',
  p_aop_debug          in varchar2 default 'No',
  p_prepend_files_json in clob default null,
  p_append_files_json  in clob default null,
  p_templates_json     in clob default null,
  p_output_json        in clob default null)
  return blob
as
  l_aop_json          clob;
  l_template_clob     clob;
  l_template_type     varchar2(10);
  l_output_type       varchar2(10);
  l_blob              blob;
  l_error_description varchar2(32767);
  l_max_amount        integer := dbms_lob.lobmaxsize;
  l_amount            binary_integer := 8000; 
  l_dest_offset       integer := 1 ;
  l_src_offset        integer := 1 ;
  l_blob_csid         integer := dbms_lob.default_csid;
  l_lang_context      integer := dbms_lob.default_lang_ctx;
  l_warning           integer := dbms_lob.warn_inconvertible_char;
  l_req               utl_http.req;
  l_res               utl_http.resp;
  l_buffer            varchar2(32767); 
  l_raw_buf           raw(32767);
  l_step              pls_integer := 12000;
  l_head_name         varchar2(4000);
  l_head_value        varchar2(32767);
  l_output_json       clob;
  l_aop_json_length   integer;
begin
  if p_template is not null
  then
    l_template_clob := blob2clobbase64(p_template);
    l_template_clob := replace(l_template_clob, chr(13) || chr(10), null);
    l_template_clob := replace(l_template_clob, '"', '\u0022');
  end if;

  if p_template_type is not null
  then
    l_template_type := p_template_type;
  elsif p_template_type is null and p_template is not null
  then
    if dbms_lob.instr(p_template, utl_raw.cast_to_raw('ppt/presentation'))> 0
    then
      l_template_type := 'pptx';
    elsif dbms_lob.instr(p_template, utl_raw.cast_to_raw('worksheets/'))> 0
    then
      l_template_type := 'xlsx';
    elsif dbms_lob.instr(p_template, utl_raw.cast_to_raw('word/document'))> 0
    then
      l_template_type := 'docx';
    elsif dbms_lob.instr(p_template, utl_raw.cast_to_raw('html'))> 0
    then
      l_template_type := 'html';
    else
      l_template_type := 'txt';
    end if;
  else
    -- use AOP Template 
    l_template_type := '';
  end if;

  if p_output_type is null
  then
    l_output_type := l_template_type;
  else
    l_output_type := p_output_type;
  end if;

  if p_output_json is null
  then
    l_output_json := ' "output_converter": "' || g_output_converter || '" ';
  else
    l_output_json := ' "output_converter": "' || g_output_converter || '", ' || p_output_json;
  end if;

  l_aop_json := '
  {
      "version": "***AOP_VERSION***",
      "api_key": "***AOP_API_KEY***",
      "mode": "***AOP_MODE***",
      "template": {
        "file":"***AOP_TEMPLATE_BASE64***",
         "template_type": "***AOP_TEMPLATE_TYPE***"
      },
      "templates": 
        ***AOP_TEMPLATES_JSON***,
      "output": {
        "output_encoding": "raw",
        "output_type": "***AOP_OUTPUT_TYPE***",
        ***AOP_OUTPUT_JSON***        
      },
      "files":
        ***AOP_DATA_JSON***,
      "prepend_files":
        ***AOP_PREPEND_FILES_JSON***,
      "append_files":
        ***AOP_APPEND_FILES_JSON***  
  }';

  l_aop_json := replace(l_aop_json, '***AOP_VERSION***', c_aop_version);
  l_aop_json := replace(l_aop_json, '***AOP_API_KEY***', p_api_key);
  l_aop_json := replace(l_aop_json, '***AOP_MODE***', p_aop_mode);
  l_aop_json := replace_with_clob(l_aop_json, '***AOP_TEMPLATE_BASE64***', l_template_clob);
  l_aop_json := replace_with_clob(l_aop_json, '***AOP_TEMPLATE_TYPE***', l_template_type);
  l_aop_json := replace(l_aop_json, '***AOP_OUTPUT_TYPE***', l_output_type);
  l_aop_json := replace(l_aop_json, '***AOP_OUTPUT_JSON***', l_output_json);
  l_aop_json := replace_with_clob(l_aop_json, '***AOP_DATA_JSON***', p_data_json);
  l_aop_json := replace_with_clob(l_aop_json, '***AOP_PREPEND_FILES_JSON***', nvl(p_prepend_files_json,'[]'));
  l_aop_json := replace_with_clob(l_aop_json, '***AOP_APPEND_FILES_JSON***', nvl(p_append_files_json,'[]'));
  l_aop_json := replace_with_clob(l_aop_json, '***AOP_TEMPLATES_JSON***', nvl(p_templates_json,'[]'));
  l_aop_json := replace(l_aop_json, '\\n', '\n');
  dbms_lob.createtemporary(l_blob, false);
  dbms_lob.converttoblob (
        dest_lob    => l_blob,
        src_clob    => l_aop_json,
        amount      => l_max_amount,
        dest_offset => l_dest_offset,
        src_offset  => l_src_offset,
        blob_csid   => l_blob_csid,
        lang_context=> l_lang_context,
        warning     => l_warning
    );
  if p_aop_debug != 'Local'
  then 
    -- If using HTTPS, open a wallet containing the trusted root certificate.
    if g_wallet_path is not null
      -- and g_wallet_pwd is not null 
    then
      sys.utl_http.set_wallet(g_wallet_path, g_wallet_pwd);
    end if;
    
    -- Call AOP
    l_aop_json_length := sys.dbms_lob.getlength(l_blob);
    l_req := sys.utl_http.begin_request(p_aop_url, 'POST', 'HTTP/1.1');
    sys.utl_http.set_header(l_req, 'Content-Type', 'application/json'); 
    sys.utl_http.set_header(l_req, 'Content-Length', l_aop_json_length);  

    if l_aop_json_length > 0 then
        declare
            l_raw              raw(8000);
            l_amount           number := 8000;
            l_offset           number := 1;
        begin
            while (l_offset <= l_aop_json_length) loop
                sys.dbms_lob.read(l_blob, l_amount, l_offset, l_raw);
                sys.utl_http.write_raw(l_req, l_raw);
                l_offset := l_offset + l_amount;
            end loop;
        end;
    end if;


    l_res := sys.utl_http.get_response(l_req);
    -- code and header
    if l_res.status_code = utl_http.http_ok
    then
      l_error_description := null;
    elsif l_res.status_code = 503
    then
      l_error_description := 'AOP Server not running or can not be reached.';
    elsif l_res.status_code = 500
    then
      for i in 1 .. sys.utl_http.get_header_count(l_res) loop
        sys.utl_http.get_header(l_res, i, l_head_name, l_head_value);
        if l_head_name = 'error_description'
        then
          l_error_description := l_head_value;
          -- errors returned by AOP server are base64 encoded
          l_error_description := utl_encode.text_decode(l_error_description, 'AL32UTF8', utl_encode.base64);
        end if;  
      end loop;
    else
      l_error_description := 'Unknown error. Check AOP server logs.';
    end if;

    if l_error_description is not null
    then
      raise_application_error(-20002, 'Issue returned by AOP Service (REST call: ' || l_res.status_code || '): ' || CHR(10) || l_error_description);

    else
      -- body
      sys.dbms_lob.createtemporary (lob_loc => l_blob, cache => true );
      begin
        loop
          sys.utl_http.read_raw(l_res, l_raw_buf);        
          sys.dbms_lob.writeappend( l_blob, sys.utl_raw.length(l_raw_buf), l_raw_buf );
        end loop;
      exception
      when others 
      then
        null; -- end reading output
      end;    
      sys.utl_http.end_response(l_res);
    end if;

  end if;

  -- return print
  return l_blob;

end make_aop_request;

end aop_plsql_only_pkg;
/
create or replace package body aop_convert25_pkg wrapped 
a000000
1
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
b
4685 1477
+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

/
