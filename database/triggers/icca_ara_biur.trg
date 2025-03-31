create or replace trigger icca_ara_biur
  before insert or update on icca_areas for each row
declare
begin
  --
  if inserting
  then
    --
    :new.created_by     := nvl( v('APP_USER'), user);
    :new.created_date   := sysdate;
    :new.modified_by    := nvl( v('APP_USER'), user);
    :new.modified_date  := sysdate;
    --
  elsif updating
  then
    --
    :new.modified_by    := nvl( v('APP_USER'), user);
    :new.modified_date  := sysdate;
    --
  end if;
  --
end icca_ara_biur;
/
