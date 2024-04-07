drop type uuid_t force;
create or replace type uuid_t
/** 
 * Creates and holds UUIDs
 */
as object (
   the_string varchar2(36),
   
   constructor function uuid_t
      return self as result,
      
   map member function to_string
      return varchar2
      
)
final;
/

show errors;

create or replace type uuid_tab_t as table of uuid_t;
/
show errors;

create or replace public synonym cwms_t_uuid for uuid_t;
create or replace public synonym cwms_tab_t_uuid for uuid_tab_t;

