-- drop user icca cascade;
-- DROP TABLESPACE icca_ts INCLUDING CONTENTS AND DATAFILES CASCADE CONSTRAINTS;

CREATE TABLESPACE icca_ts DATAFILE 'icca.dbf'
size 500m
autoextend on
next 100m
maxsize unlimited;

-- PW changed on PRD
create user icca identified by icca DEFAULT TABLESPACE icca_ts;
grant create SESSION  to icca;

grant create cluster to icca;
grant create dimension to icca;
grant create indextype to icca;
grant create job to icca;
grant create materialized view to icca;
grant create mle to icca;
grant create operator to icca;
grant create procedure to icca;
grant create property graph to icca;
grant create sequence to icca;
grant create synonym to icca;
grant create table to icca;
grant create trigger to icca;
grant create type to icca;
grant create view to icca;
grant execute dynamic mle to icca;
grant create any context to icca;


alter user icca quota unlimited on icca_ts;




