create or replace trigger icca_kcn_biur
  before insert or update on icca_ket_clients for each row
declare
begin
  --
  if inserting
  then
    --
    :new.created_by     := upper(coalesce(regexp_substr(sys_context('userenv', 'client_identifier'), '^[^:]*'), user));
    :new.created_date   := sysdate;
    :new.modified_by    := upper(coalesce(regexp_substr(sys_context('userenv', 'client_identifier'), '^[^:]*'), user));
    :new.modified_date  := sysdate;
    --
  elsif updating
  then
    --
    :new.modified_by    := upper(coalesce(regexp_substr(sys_context('userenv', 'client_identifier'), '^[^:]*'), user));
    :new.modified_date  := sysdate;
    --
  end if;
  --
end icca_kcn_biur;
/
