WHENEVER sqlerror exit sql.sqlcode
SET serveroutput on


create or replace
PACKAGE BODY CWMS_EMBANK AS

procedure cat_structure_type(
    p_structure_type_cat OUT sys_refcursor
)
AS
    l_cursor sys_refcursor
BEGIN

open l_cursor for
    select * from at_lu_embank_structure_type;


p_structure_type_cat := convert_to_lookup(l_cursor);
return p_structure_type_cat;

END cat_structure_type



function convert_to_lookup(p_lookup_cursor IN sys_refcursor)
begin
select * from p_lookup_cursor into 
end convert_to_lookup

END CWMS_EMBANK;
 
/
show errors;