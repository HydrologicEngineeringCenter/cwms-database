CREATE TYPE source_type
-- not documented, used only in routine body
AS OBJECT (
   source_id   VARCHAR2 (16),
   gage_id     VARCHAR2 (32)
);
/


create or replace public synonym cwms_t_source for source_type;

