set define off
set serveroutput on


prompt start_tables.sql
@tables/start_tables.sql

prompt start_triggers.sql
@triggers/start_triggers.sql

prompt start_scripts.sql
@scripts/start_scripts.sql

prompt start_packages.sql
@packages/start_packages.sql

prompt start_package_bodies.sql
@package_bodies/start_package_bodies.sql

prompt start_views.sql
@views/start_views.sql

prompt api.sql
@api/start_api.sql

-- prompt apex_app


prompt recompile_schema.sql
@recompile_schema.sql