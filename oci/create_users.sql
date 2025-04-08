create user icca identified by TnKyrXMfK4KRTQ73JKY;
GRANT CONNECT, RESOURCE TO icca;
ALTER USER icca QUOTA UNLIMITED ON data;
GRANT CREATE ANY CONTEXT, CREATE JOB TO icca;

BEGIN
  ORDS.ENABLE_SCHEMA(p_enabled => TRUE,
                    p_schema => 'ICCA',
--                    p_url_mapping_type => 'iccaapi',
--                    p_url_mapping_pattern => 'iccaapi',
                    p_auto_rest_auth => FALSE
                    );
  COMMIT;
END;
/


