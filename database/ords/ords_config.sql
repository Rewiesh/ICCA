BEGIN
  ORDS.ENABLE_SCHEMA(p_enabled => true,
                    p_schema => 'ICCA',
                    p_url_mapping_type => 'BASE_PATH',
--                    p_url_mapping_pattern => 'iccaapi',
                    p_auto_rest_auth => FALSE
                    );
  COMMIT;
END;