/**
  * convience function to render base and -sub values.
  * @param base value
  * @param sub value, can be null
  * @return base[-sub] where [] indicates optional and not rendered if p2 is null
  */
create or replace function dash (base varchar2, sub varchar2) return varchar2 as
begin
    return base || case when sub is not null then '-' end || sub;
end;
/