create or replace trigger icca_cat_biur
  before insert or update on icca_categories for each row
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
end icca_cat_biur;
/
