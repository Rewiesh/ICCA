BEGIN
  DBMS_SCHEDULER.create_job (
    job_name        => 'ICCA_KEEP_ALIVE_JOB',
    job_type        => 'PLSQL_BLOCK',
    job_action      => '
      BEGIN
        INSERT INTO KEEP_ALIVE_LOG (run_time) VALUES (CURRENT_TIMESTAMP);
        COMMIT;
      END;',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=DAILY; BYHOUR=8',
    enabled         => TRUE
  );
END;
/