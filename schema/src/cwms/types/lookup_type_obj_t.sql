CREATE TYPE lookup_type_obj_t
/**
 * Holds data from one of several similarly-structured tables in the database.
 * Primarily used to hold brief names and descriptions for REGI/ROWCPS application.
 *
 * @see type lookup_table_tab_t
 *
 * @member office_id     The office that owns the information
 * @member display_value The brief name or identifier
 * @member tooltip       The longer description, often targeted for a tooltip
 * @member active        A flag ('T' or 'F') that specifies whether this item is active
 */
AS
  OBJECT
  (
    office_id     VARCHAR2 (16),      -- the office id for this lookup type
    display_value VARCHAR2(25 byte),  --The value to display for this lookup record
    tooltip       VARCHAR2(255 byte), --The tooltip or meaning of this lookup record
    active        VARCHAR2(1 byte)    --Whether this lookup record entry is currently active
  );
/


  
create or replace public synonym cwms_t_lookup_type_obj_t for lookup_type_obj_t;

