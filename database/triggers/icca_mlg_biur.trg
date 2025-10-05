create or replace trigger icca_mlg_biur
  before insert or update on icca_mail_log for each row
declare
begin
  --
  if inserting
  then
    --
    :new.created_by     := upper(coalesce(regexp_substr(sys_context('userenv', 'client_identifier'), '^[^:]*'), user));
    :new.created_date   := sysdate;
    --
  end if;
  --
end icca_mlg_biur;
/
